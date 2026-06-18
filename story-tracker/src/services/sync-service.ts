import type { ReadingProgressPayload } from '../types/api';
import type { ReadingInfo, ReadingSession, SyncNowResult } from '../types/reading';
import { ApiError } from './api-client';
import { createReadingProgressService } from './reading-progress-service';
import { tokenManager } from '../auth/token-manager';
import { offlineQueue } from '../storage/offline-queue';
import { storageService } from '../storage/storage-service';
import { logger } from '../utils/logger';

function formatSyncError(error: unknown): string {
  if (error instanceof ApiError) return error.message;
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

    const payload = this.toPayload(info);

    try {
      if (!navigator.onLine) {
        await this.queueOffline(payload, 'Offline');
        return false;
      }

      const token = await tokenManager.ensureValidToken();
      if (!token) {
        await this.queueOffline(payload, 'Not signed in');
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
      return { synced: 0, failed: 0, pushedLatest: false, error: 'Sync already in progress' };
    }
    this.syncing = true;

    let synced = 0;
    let failed = 0;
    let pushedLatest = false;
    let lastError: string | undefined;

    try {
      await storageService.setSyncStatus({
        ...(await storageService.getSyncStatus()),
        state: 'syncing',
      });

      const token = await tokenManager.ensureValidToken();
      if (!token) {
        const message = 'Not signed in. Use Continue to Personal OS in the extension popup.';
        const pendingCount = await offlineQueue.size();
        await storageService.setSyncStatus({
          state: 'error',
          lastSyncAt: (await storageService.getSyncStatus()).lastSyncAt,
          pendingCount,
          lastError: message,
        });
        return { synced: 0, failed: 1, pushedLatest: false, error: message };
      }

      const latest = await this.getLatestLocalReading();
      if (latest) {
        const payload = this.toPayload(latest.readingInfo);
        try {
          await this.pushToServer(payload);
          synced++;
          pushedLatest = true;
        } catch (error) {
          failed++;
          lastError = formatSyncError(error);
          await this.queueOffline(payload, lastError);
          logger.error('Failed to push latest reading session', error);
        }
      }

      const flush = await this.flushQueueInternal();
      synced += flush.synced;
      failed += flush.failed;
      if (flush.lastError) lastError = flush.lastError;

      if (failed > 0 && synced === 0) {
        await storageService.setSyncStatus({
          state: 'error',
          lastSyncAt: (await storageService.getSyncStatus()).lastSyncAt,
          pendingCount: await offlineQueue.size(),
          lastError: lastError ?? 'Sync failed',
        });
      }

      return { synced, failed, pushedLatest, error: failed > 0 ? lastError : undefined };
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
      await storageService.setSyncStatus({
        state: 'error',
        lastSyncAt: (await storageService.getSyncStatus()).lastSyncAt,
        pendingCount: events.length,
        lastError: 'Not signed in',
      });
      return { synced: 0, failed: events.length, lastError: 'Not signed in' };
    }

    const readingProgress = createReadingProgressService();
    const succeeded: string[] = [];

    for (const event of events) {
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

  private async getLatestLocalReading(): Promise<ReadingSession | null> {
    const sessions = await storageService.get('readingSessions');
    const sorted = Object.values(sessions).sort((a, b) => b.lastUpdatedAt - a.lastUpdatedAt);
    return sorted[0] ?? null;
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
