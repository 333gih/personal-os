import browser from 'webextension-polyfill';
import type { AuthMode } from '../auth/types';
import type { ReadingInfo, ReadingSession } from '../types/reading';
import { syncService } from '../services/sync-service';
import { authService } from '../auth/auth-service';
import { storageService } from '../storage/storage-service';
import { MESSAGE_TYPES, type ExtensionMessage, type MessageResponse } from '../shared/messages';
import { onConnectivityChange } from '../services/reading-progress-service';
import { logger } from '../utils/logger';

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
    });

    onConnectivityChange((online) => {
      if (online) void syncService.flushQueue();
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

    logger.info('Sync manager initialized');
  }

  private startSyncInterval(intervalMs: number): void {
    if (this.syncInterval) clearInterval(this.syncInterval);
    this.syncInterval = setInterval(() => {
      void syncService.flushQueue();
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
          return { success: true, data: await syncService.flushQueue() };

        case MESSAGE_TYPES.LOGIN:
          return {
            success: true,
            data: await authService.login(
              message.payload as { email: string; password: string; mode: AuthMode },
            ),
          };

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

        case MESSAGE_TYPES.GET_AUTH_STATE:
          return { success: true, data: await authService.getAuthState() };

        case MESSAGE_TYPES.GET_SYNC_STATUS:
          return { success: true, data: await storageService.getSyncStatus() };

        case MESSAGE_TYPES.GET_READING_HISTORY:
          return { success: true, data: await storageService.getReadingHistory() };

        case MESSAGE_TYPES.GET_CURRENT_READING: {
          const sessions = await storageService.get('readingSessions');
          const active = this.activeTabId ?
            Object.values(sessions).sort((a, b) => b.lastUpdatedAt - a.lastUpdatedAt)[0]
          : Object.values(sessions).sort((a, b) => b.lastUpdatedAt - a.lastUpdatedAt)[0];
          return { success: true, data: active ?? null };
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
    const session: ReadingSession = {
      id: `${info.storyId}:${info.chapterId ?? 'default'}`,
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
    });

    const synced = await syncService.syncReadingUpdate(info);

    if (info.isUnload || forceFlush) {
      await syncService.flushQueue();
    }

    return { success: true, data: { synced } };
  }
}

export const syncManager = new SyncManager();
