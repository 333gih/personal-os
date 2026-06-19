import type { ReadingProgressPayload } from '../types/api';
import type { ReadingInfo, SyncNowResult } from '../types/reading';
import { ApiError } from './api-client';
import { createReadingProgressService } from './reading-progress-service';
import { tokenManager } from '../auth/token-manager';
import { offlineQueue } from '../storage/offline-queue';
import { storageService } from '../storage/storage-service';
import { logger } from '../utils/logger';
import { shouldPersistChapterProgress } from '../utils/chapter-progress';
import { historyEntryToReadingInfo } from '../utils/reading-display';

function formatSyncError(error: unknown): string {
  if (error instanceof ApiError) {
    if (
      error.status === 503 &&
      /ring-balancer|failure to get a peer/i.test(error.message)
    ) {
      return 'Personal OS API is down (Kong has no healthy backend). Fix gateway upstream — see deploy/fash-integration/README.md.';
    }
    if (error.status === 502 || error.status === 504) {
      return `Personal OS API unavailable (${error.status}). Try again after the server is back online.`;
    }
    return error.message;
  }
  if (error instanceof Error) return error.message;
  return 'Sync failed';
}

export class SyncService {
  private syncing = false;

  async syncReadingUpdate(info: ReadingInfo): Promise<boolean> {
    const settings = await storageService.getSettings();
    if (!settings.autoSync) return false;

    const siteEnabled = settings.enabledSites[info.metadata?.parser as string] ?? true;
    if (!siteEnabled) {
      logger.debug('Site disabled, skipping sync');
      return false;
    }

    const history = await storageService.getReadingHistory();
    const existing = history.find((entry) => entry.storyId === info.storyId) ?? null;
    if (!shouldPersistChapterProgress(existing, info)) {
      logger.debug('Skipped sync — incoming chapter below stored highest', {
        storyId: info.storyId,
      });
      return false;
    }

    const payload = this.toPayload(info);

    try {
      if (!navigator.onLine) {
        await this.queueOffline(payload, 'Offline');
        return false;
      }

      const token = await tokenManager.ensureValidToken();
      if (!token) {
        return false;
      }

      return await this.pushToServer(payload);
    } catch (error) {
      const message = formatSyncError(error);
      logger.error('Sync failed, queueing offline', error);
      await this.queueOffline(payload, message);
      return false;
    }
  }

  /** Push latest local reading + flush offline queue (manual sync and periodic sync). */
  async syncNow(): Promise<SyncNowResult> {
    if (this.syncing) {
      return {
        synced: 0,
        failed: 0,
        pushedLatest: false,
        localCount: 0,
        serverCount: 0,
        error: 'Sync already in progress',
      };
    }
    this.syncing = true;

    let synced = 0;
    let failed = 0;
    let pushedLatest = false;
    let lastError: string | undefined;
    const localPayloads = await this.collectLocalPayloads();
    const localCount = localPayloads.length;

    try {
      await storageService.setSyncStatus({
        ...(await storageService.getSyncStatus()),
        state: 'syncing',
      });

      const token = await tokenManager.ensureValidToken();
      if (!token) {
        const authError = 'Not signed in or session expired. Sign in again via Personal OS.';
        await storageService.setSyncStatus({
          state: 'error',
          lastSyncAt: (await storageService.getSyncStatus()).lastSyncAt,
          pendingCount: await offlineQueue.size(),
          lastError: authError,
        });
        return {
          synced: 0,
          failed: 1,
          pushedLatest: false,
          localCount,
          serverCount: 0,
          error: authError,
        };
      }

      const localPush = await this.pushAllLocalProgress(localPayloads);
      synced += localPush.synced;
      failed += localPush.failed;
      if (localPush.lastError) lastError = localPush.lastError;
      pushedLatest = localPush.synced > 0;

      const flush = await this.flushQueueInternal();
      synced += flush.synced;
      failed += flush.failed;
      if (flush.lastError) lastError = flush.lastError;

      const serverCount = await this.fetchServerStoryCount();

      if (failed > 0 && synced === 0) {
        await storageService.setSyncStatus({
          state: 'error',
          lastSyncAt: (await storageService.getSyncStatus()).lastSyncAt,
          pendingCount: await offlineQueue.size(),
          lastError: lastError ?? 'Sync failed',
        });
      }

      return {
        synced,
        failed,
        pushedLatest,
        localCount,
        serverCount,
        error: failed > 0 ? lastError : undefined,
      };
    } finally {
      this.syncing = false;
    }
  }

  async flushQueue(): Promise<{ synced: number; failed: number }> {
    if (this.syncing) return { synced: 0, failed: 0 };
    this.syncing = true;
    try {
      return await this.flushQueueInternal();
    } finally {
      this.syncing = false;
    }
  }

  private async flushQueueInternal(): Promise<{
    synced: number;
    failed: number;
    lastError?: string;
  }> {
    let synced = 0;
    let failed = 0;
    let lastError: string | undefined;

    const events = await offlineQueue.peek();
    if (events.length === 0) {
      if ((await storageService.getSyncStatus()).state === 'syncing') {
        await this.setIdleStatus();
      }
      return { synced: 0, failed: 0 };
    }

    const token = await tokenManager.ensureValidToken();
    if (!token) {
      return { synced: 0, failed: 0 };
    }

    const readingProgress = createReadingProgressService();
    const succeeded: string[] = [];

    for (const event of events) {
      if (!(await this.shouldPushPayload(event.payload))) {
        succeeded.push(event.id);
        continue;
      }

      try {
        await readingProgress.saveProgress(event.payload);
        succeeded.push(event.id);
        synced++;
      } catch (error) {
        failed++;
        lastError = formatSyncError(error);
        await offlineQueue.markAttempted([event.id]);
        logger.error(`Failed to sync event ${event.id}`, error);
      }
    }

    await offlineQueue.dequeue(succeeded);
    await storageService.setSyncStatus({
      state: failed > 0 ? 'error' : 'idle',
      lastSyncAt: Date.now(),
      pendingCount: await offlineQueue.size(),
      lastError: failed > 0 ? lastError : undefined,
    });

    return { synced, failed, lastError };
  }

  private async pushToServer(payload: ReadingProgressPayload): Promise<boolean> {
    await tokenManager.requireAccessToken();
    const readingProgress = createReadingProgressService();
    await readingProgress.saveProgress(payload);
    await offlineQueue.removeByStoryId(payload.storyId);

    await storageService.setSyncStatus({
      state: 'idle',
      lastSyncAt: Date.now(),
      pendingCount: await offlineQueue.size(),
      lastError: undefined,
    });

    logger.info('Reading progress synced to Personal OS', { storyId: payload.storyId });
    return true;
  }

  private async queueOffline(
    payload: ReadingProgressPayload,
    lastError: string,
  ): Promise<void> {
    if (!(await this.shouldPushPayload(payload))) {
      return;
    }

    await offlineQueue.enqueue(payload);
    await storageService.setSyncStatus({
      state: navigator.onLine ? 'error' : 'offline',
      lastSyncAt: (await storageService.getSyncStatus()).lastSyncAt,
      pendingCount: await offlineQueue.size(),
      lastError,
    });
  }

  private async setIdleStatus(): Promise<void> {
    await storageService.setSyncStatus({
      state: 'idle',
      lastSyncAt: Date.now(),
      pendingCount: await offlineQueue.size(),
      lastError: undefined,
    });
  }

  /** Push every story in local history (and any session-only stories) to the server. */
  private async pushAllLocalProgress(payloads: ReadingProgressPayload[]): Promise<{
    synced: number;
    failed: number;
    lastError?: string;
  }> {
    let synced = 0;
    let failed = 0;
    let lastError: string | undefined;

    for (const payload of payloads) {
      if (!(await this.shouldPushPayload(payload))) continue;

      try {
        await this.pushToServer(payload);
        synced++;
      } catch (error) {
        failed++;
        lastError = formatSyncError(error);
        await this.queueOffline(payload, lastError);
        logger.error('Failed to push local reading progress', { storyId: payload.storyId }, error);
      }
    }

    return { synced, failed, lastError };
  }

  private async collectLocalPayloads(): Promise<ReadingProgressPayload[]> {
    const history = await storageService.getReadingHistory();
    const payloads: ReadingProgressPayload[] = [];
    const seen = new Set<string>();

    for (const entry of history) {
      payloads.push(this.toPayload(historyEntryToReadingInfo(entry)));
      seen.add(entry.storyId);
    }

    const sessions = await storageService.get('readingSessions');
    for (const session of Object.values(sessions)) {
      const { storyId } = session.readingInfo;
      if (seen.has(storyId)) continue;
      payloads.push(this.toPayload(session.readingInfo));
      seen.add(storyId);
    }

    return payloads;
  }

  private async fetchServerStoryCount(): Promise<number> {
    try {
      const service = createReadingProgressService();
      const response = await service.getCurrentProgress();
      return response.items.length;
    } catch (error) {
      logger.warn('Failed to verify reading progress on server', error);
      return -1;
    }
  }

  private async shouldPushPayload(payload: ReadingProgressPayload): Promise<boolean> {
    const history = await storageService.getReadingHistory();
    const existing = history.find((entry) => entry.storyId === payload.storyId) ?? null;
    return shouldPersistChapterProgress(existing, {
      storyId: payload.storyId,
      storyTitle: payload.storyTitle,
      chapterId: payload.chapterId,
      chapterTitle: payload.chapterTitle,
      currentUrl: payload.currentUrl,
      progress: payload.progress,
      metadata: payload.metadata,
    });
  }

  private toPayload(info: ReadingInfo): ReadingProgressPayload {
    let hostname = '';
    try {
      hostname = new URL(info.currentUrl).hostname;
    } catch {
      hostname = '';
    }

    return {
      storyId: info.storyId,
      storyTitle: info.storyTitle,
      chapterId: info.chapterId,
      chapterTitle: info.chapterTitle,
      currentUrl: info.currentUrl,
      progress: { ...info.progress },
      metadata: {
        ...info.metadata,
        page_kind: 'chapter',
        hostname,
      },
      clientTimestamp: Date.now(),
    };
  }
}

export const syncService = new SyncService();
