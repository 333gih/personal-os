import type { ReadingProgressPayload } from '../types/api';
import type { ReadingInfo } from '../types/reading';
import { createReadingProgressService } from './reading-progress-service';
import { tokenManager } from '../auth/token-manager';
import { offlineQueue } from '../storage/offline-queue';
import { storageService } from '../storage/storage-service';
import { logger } from '../utils/logger';

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
        await this.queueOffline(payload);
        return false;
      }

      const token = await tokenManager.ensureValidToken();
      if (!token) {
        await this.queueOffline(payload);
        return false;
      }

      return await this.pushToServer(payload);
    } catch (error) {
      logger.error('Sync failed, queueing offline', error);
      await this.queueOffline(payload);
      return false;
    }
  }

  async flushQueue(): Promise<{ synced: number; failed: number }> {
    if (this.syncing) return { synced: 0, failed: 0 };
    this.syncing = true;

    let synced = 0;
    let failed = 0;

    try {
      await storageService.setSyncStatus({
        ...(await storageService.getSyncStatus()),
        state: 'syncing',
      });

      const events = await offlineQueue.peek();
      if (events.length === 0) {
        await this.setIdleStatus();
        return { synced: 0, failed: 0 };
      }

      const token = await tokenManager.ensureValidToken();
      if (!token) {
        await storageService.setSyncStatus({
          state: 'offline',
          lastSyncAt: null,
          pendingCount: events.length,
          lastError: 'Not authenticated',
        });
        return { synced: 0, failed: events.length };
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
          await offlineQueue.markAttempted([event.id]);
          logger.error(`Failed to sync event ${event.id}`, error);
        }
      }

      await offlineQueue.dequeue(succeeded);
      await storageService.setSyncStatus({
        state: failed > 0 ? 'error' : 'idle',
        lastSyncAt: Date.now(),
        pendingCount: (await offlineQueue.size()),
        lastError: failed > 0 ? `${failed} events failed to sync` : undefined,
      });
    } finally {
      this.syncing = false;
    }

    return { synced, failed };
  }

  private async pushToServer(payload: ReadingProgressPayload): Promise<boolean> {
    const readingProgress = createReadingProgressService();
    await readingProgress.saveProgress(payload);

    await storageService.setSyncStatus({
      state: 'idle',
      lastSyncAt: Date.now(),
      pendingCount: await offlineQueue.size(),
    });

    return true;
  }

  private async queueOffline(payload: ReadingProgressPayload): Promise<void> {
    await offlineQueue.enqueue(payload);
    await storageService.setSyncStatus({
      state: navigator.onLine ? 'error' : 'offline',
      lastSyncAt: (await storageService.getSyncStatus()).lastSyncAt,
      pendingCount: await offlineQueue.size(),
      lastError: navigator.onLine ? 'Sync failed' : 'Offline',
    });
  }

  private async setIdleStatus(): Promise<void> {
    await storageService.setSyncStatus({
      state: 'idle',
      lastSyncAt: Date.now(),
      pendingCount: 0,
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
