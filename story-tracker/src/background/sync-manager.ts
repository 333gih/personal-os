import browser from 'webextension-polyfill';
import type { AuthMode } from '../auth/types';
import type { ReadingInfo, ReadingSession } from '../types/reading';
import { syncService } from '../services/sync-service';
import { authService } from '../auth/auth-service';
import type { WebAuthHandoffPayload } from '../config/personal-os-fe';
import { startPersonalOsWebAuth, processWebAuthHandoff } from '../auth/web-auth';
import { storageService } from '../storage/storage-service';
import { MESSAGE_TYPES, type ExtensionMessage, type MessageResponse } from '../shared/messages';
import { onConnectivityChange } from '../services/reading-progress-service';
import { pullRemoteProgress } from '../services/pull-progress';
import { registerKnownContentScripts, maybeDiscoverOrigin } from './origin-registry';
import { logger } from '../utils/logger';
import {
  canSaveGuestStory,
  getGuestStatus,
  GUEST_LIMIT_CODE,
  GUEST_LIMIT_MESSAGE,
  isGuestMode,
} from '../guest/guest-mode';
import { GUEST_MAX_STORIES } from '../shared/constants';

export class SyncManager {
  private syncInterval: ReturnType<typeof setInterval> | null = null;
  private activeTabId: number | null = null;

  async init(): Promise<void> {
    const settings = await storageService.getSettings();
    this.startSyncInterval(settings.syncIntervalMs);

    browser.storage.onChanged.addListener((changes, area) => {
      if (area === 'local' && changes.settings) {
        const newSettings = changes.settings.newValue as { syncIntervalMs: number };
        this.startSyncInterval(newSettings.syncIntervalMs);
      }
      if (area === 'local' && changes.auth?.newValue) {
        void this.bootstrapCloudSync();
      }
    });

    onConnectivityChange((online) => {
      void isGuestMode().then((guest) => {
        if (!guest && online) void syncService.syncNow();
      });
    });

    browser.tabs.onActivated.addListener(({ tabId }) => {
      this.activeTabId = tabId;
    });

    browser.tabs.onRemoved.addListener((tabId) => {
      if (this.activeTabId === tabId) this.activeTabId = null;
    });

    browser.runtime.onMessage.addListener((message, _sender, sendResponse) => {
      void this.handleMessage(message as ExtensionMessage).then(sendResponse);
      return true;
    });

    browser.tabs.onUpdated.addListener((_tabId, changeInfo, tab) => {
      if (changeInfo.status === 'complete' && tab.url) {
        void maybeDiscoverOrigin(tab.url);
      }
    });

    void registerKnownContentScripts();
    void this.bootstrapCloudSync();

    logger.info('Sync manager initialized');
  }

  private async bootstrapCloudSync(): Promise<void> {
    if (await isGuestMode()) {
      await storageService.setSyncStatus({
        state: 'idle',
        lastSyncAt: null,
        pendingCount: 0,
        lastError: undefined,
      });
      return;
    }
    void pullRemoteProgress().then(() => syncService.syncNow());
  }

  private startSyncInterval(intervalMs: number): void {
    if (this.syncInterval) clearInterval(this.syncInterval);
    this.syncInterval = setInterval(() => {
      void isGuestMode().then((guest) => {
        if (!guest) void syncService.syncNow();
      });
    }, intervalMs);
  }

  private async handleMessage(
    message: ExtensionMessage,
  ): Promise<MessageResponse<unknown>> {
    try {
      switch (message.type) {
        case MESSAGE_TYPES.READING_UPDATE:
        case MESSAGE_TYPES.MANUAL_SAVE:
          return this.handleReadingUpdate(
            message.payload as ReadingInfo & { isUnload?: boolean },
            false,
          );

        case MESSAGE_TYPES.CHAPTER_CHANGED:
          return this.handleReadingUpdate(
            message.payload as ReadingInfo & { isUnload?: boolean },
            true,
          );

        case MESSAGE_TYPES.SYNC_NOW:
          return { success: true, data: await syncService.syncNow() };

        case MESSAGE_TYPES.LOGIN:
          return {
            success: true,
            data: await authService.login(
              message.payload as { email: string; password: string; mode: AuthMode },
            ),
          };

        case MESSAGE_TYPES.START_WEB_AUTH:
          return { success: true, data: await startPersonalOsWebAuth() };

        case MESSAGE_TYPES.WEB_AUTH_HANDOFF:
          return processWebAuthHandoff(message.payload as WebAuthHandoffPayload);

        case MESSAGE_TYPES.REQUEST_OTP: {
          const payload = message.payload as { email: string; mode: 'commercial' };
          const result = await authService.requestOtp(payload.email);
          return { success: true, data: result };
        }

        case MESSAGE_TYPES.VERIFY_OTP:
          return {
            success: true,
            data: await authService.verifyOtp(
              message.payload as { email: string; otp: string; mode: 'commercial' },
            ),
          };

        case MESSAGE_TYPES.LOGOUT:
          await authService.logout();
          return { success: true };

        case MESSAGE_TYPES.PING:
          return { success: true, data: { ok: true } };

        case MESSAGE_TYPES.GET_AUTH_STATE: {
          const valid = await authService.ensureSession();
          return {
            success: true,
            data: valid ? await authService.getAuthState() : null,
          };
        }

        case MESSAGE_TYPES.GET_SYNC_STATUS: {
          const syncStatus = await storageService.getSyncStatus();
          return {
            success: true,
            data: { ...syncStatus, online: navigator.onLine },
          };
        }

        case MESSAGE_TYPES.GET_READING_HISTORY:
          return { success: true, data: await storageService.getReadingHistory() };

        case MESSAGE_TYPES.GET_GUEST_STATUS:
          return { success: true, data: await getGuestStatus() };

        case MESSAGE_TYPES.REMOVE_STORY_PROGRESS: {
          const storyId = (message.payload as { storyId?: string })?.storyId;
          if (!storyId) {
            return { success: false, error: 'Missing storyId' };
          }
          await storageService.removeStoryProgress(storyId);
          return { success: true, data: { storyId } };
        }

        case MESSAGE_TYPES.GET_CURRENT_READING: {
          const sessions = await storageService.get('readingSessions');
          const sorted = Object.values(sessions).sort(
            (a, b) => b.lastUpdatedAt - a.lastUpdatedAt,
          );
          return { success: true, data: sorted[0] ?? null };
        }

        case MESSAGE_TYPES.GET_STATE:
          return {
            success: true,
            data: {
              auth: await authService.getAuthState(),
              syncStatus: await storageService.getSyncStatus(),
              history: await storageService.getReadingHistory(),
            },
          };

        default:
          return { success: false, error: `Unknown message type: ${message.type}` };
      }
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      };
    }
  }

  private async handleReadingUpdate(
    info: ReadingInfo & { isUnload?: boolean },
    forceFlush = false,
  ): Promise<MessageResponse> {
    if (!(await canSaveGuestStory(info.storyId))) {
      logger.warn('Guest story limit reached', { storyId: info.storyId });
      return {
        success: false,
        code: GUEST_LIMIT_CODE,
        error: GUEST_LIMIT_MESSAGE,
        data: { storyCount: GUEST_MAX_STORIES, maxStories: GUEST_MAX_STORIES },
      };
    }

    const session: ReadingSession = {
      id: info.storyId,
      readingInfo: info,
      startedAt: Date.now(),
      lastUpdatedAt: Date.now(),
      siteId: (info.metadata?.parser as string) ?? 'generic',
    };

    await storageService.upsertReadingSession(session);
    await storageService.addHistoryEntry({
      storyId: info.storyId,
      storyTitle: info.storyTitle,
      chapterId: info.chapterId,
      chapterTitle: info.chapterTitle,
      currentUrl: info.currentUrl,
      progress: info.progress,
      lastReadAt: Date.now(),
      siteId: session.siteId,
      metadata: info.metadata,
    });

    let synced = false;
    if (!(await isGuestMode())) {
      synced = await syncService.syncReadingUpdate(info);
      if (synced) {
        void pullRemoteProgress();
      }

      if (info.isUnload || forceFlush) {
        await syncService.syncNow();
      }
    }

    return { success: true, data: { synced, localOnly: await isGuestMode() } };
  }
}

export const syncManager = new SyncManager();
