import type { ReadingProgressPayload } from '../types/api';
import type { ReadingHistoryEntry } from '../types/reading';
import { createReadingProgressService } from './reading-progress-service';
import { tokenManager } from '../auth/token-manager';
import { storageService } from '../storage/storage-service';
import { logger } from '../utils/logger';

type ServerReadingProgress = {
  story_id: string;
  story_title: string;
  chapter_id?: string;
  chapter_title?: string;
  current_url?: string;
  progress_percentage?: number;
  scroll_y?: number;
  reading_time_seconds?: number;
  site_id?: string;
  last_read_at?: string;
  metadata?: Record<string, unknown>;
};

function mapServerItem(item: ServerReadingProgress): ReadingProgressPayload {
  return {
    storyId: item.story_id,
    storyTitle: item.story_title,
    chapterId: item.chapter_id,
    chapterTitle: item.chapter_title,
    currentUrl: item.current_url ?? '',
    progress: {
      percentage: item.progress_percentage ?? 0,
      scrollY: item.scroll_y ?? 0,
      readingTimeSeconds: item.reading_time_seconds ?? 0,
    },
    metadata: item.metadata,
    clientTimestamp: item.last_read_at ? Date.parse(item.last_read_at) : Date.now(),
  };
}

export async function pullRemoteProgress(): Promise<number> {
  const token = await tokenManager.ensureValidToken();
  if (!token) return 0;

  try {
    const service = createReadingProgressService();
    const response = await service.getCurrentProgress();
    let merged = 0;

    for (const item of response.items) {
      const entry: ReadingHistoryEntry = {
        storyId: item.storyId,
        storyTitle: item.storyTitle,
        chapterId: item.chapterId,
        chapterTitle: item.chapterTitle,
        currentUrl: item.currentUrl,
        progress: { ...item.progress },
        lastReadAt: item.clientTimestamp,
        siteId: (item.metadata?.parser as string) ?? 'generic',
      };
      await storageService.addHistoryEntry(entry);
      merged += 1;
    }

    if (merged > 0) {
      logger.info(`Merged ${merged} reading progress items from server`);
    }
    return merged;
  } catch (error) {
    logger.warn('Failed to pull remote reading progress', error);
    return 0;
  }
}

export function mapServerReadingProgress(item: ServerReadingProgress): ReadingProgressPayload {
  return mapServerItem(item);
}
