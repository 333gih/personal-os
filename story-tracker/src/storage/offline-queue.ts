import type { ReadingProgressPayload } from '../types/api';
import type { UnsyncedEvent } from '../types/storage';
import { OFFLINE_QUEUE_MAX_SIZE } from '../shared/constants';
import { storageService } from './storage-service';
import { logger } from '../utils/logger';

export class OfflineQueue {
  async enqueue(payload: ReadingProgressPayload): Promise<UnsyncedEvent> {
    const event: UnsyncedEvent = {
      id: crypto.randomUUID(),
      payload,
      createdAt: Date.now(),
      retryCount: 0,
    };

    await storageService.update('unsyncedEvents', (events) => {
      const next = [...events, event];
      if (next.length > OFFLINE_QUEUE_MAX_SIZE) {
        logger.warn('Offline queue full, dropping oldest events');
        return next.slice(-OFFLINE_QUEUE_MAX_SIZE);
      }
      return next;
    });

    await this.updatePendingCount();
    return event;
  }

  async markAttempted(ids: string[]): Promise<void> {
    const idSet = new Set(ids);
    await storageService.update('unsyncedEvents', (events) =>
      events.map((e) =>
        idSet.has(e.id) ?
          { ...e, retryCount: e.retryCount + 1, lastAttemptAt: Date.now() }
        : e,
      ),
    );
  }

  async dequeue(ids: string[]): Promise<void> {
    await storageService.removeUnsyncedEvents(ids);
    await this.updatePendingCount();
  }

  async peek(): Promise<UnsyncedEvent[]> {
    return storageService.getUnsyncedEvents();
  }

  async size(): Promise<number> {
    const events = await this.peek();
    return events.length;
  }

  private async updatePendingCount(): Promise<void> {
    const count = await this.size();
    const status = await storageService.getSyncStatus();
    await storageService.setSyncStatus({ ...status, pendingCount: count });
  }
}

export const offlineQueue = new OfflineQueue();
