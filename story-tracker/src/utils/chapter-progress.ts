import type { ReadingHistoryEntry, ReadingInfo } from '../types/reading';
import { historyEntryToReadingInfo } from './reading-display';

type ChapterRankSource = Pick<ReadingInfo, 'chapterId' | 'chapterTitle' | 'metadata'>;

/** Numeric position used to compare chapters within the same story part. */
export function resolveChapterRank(source: ChapterRankSource): number | null {
  const meta = source.metadata;

  if (meta?.chapter_index != null) {
    const index = Number(meta.chapter_index);
    if (Number.isFinite(index) && index > 0) return index;
  }

  const candidates = [
    meta?.chuongid,
    meta?.chapter_number,
    source.chapterId?.match(/chuong-(\d+)/i)?.[1],
    source.chapterTitle?.match(/chương\s*(\d+)/i)?.[1],
  ];

  for (const value of candidates) {
    const rank = Number(String(value ?? '').trim());
    if (Number.isFinite(rank) && rank > 0) return rank;
  }

  return null;
}

export function resolveStoryPartKey(metadata?: Record<string, unknown>): string {
  const part = metadata?.part_id;
  return typeof part === 'string' && part.trim() ? part.trim() : 'default';
}

function toRankSource(entry: ReadingHistoryEntry): ChapterRankSource {
  if (entry.metadata) {
    return {
      chapterId: entry.chapterId,
      chapterTitle: entry.chapterTitle,
      metadata: entry.metadata,
    };
  }
  const info = historyEntryToReadingInfo(entry);
  return {
    chapterId: info.chapterId,
    chapterTitle: info.chapterTitle,
    metadata: info.metadata,
  };
}

/**
 * Whether incoming progress should replace stored progress.
 * Keeps the highest chapter read per story part; allows updates on the same chapter.
 */
export function shouldPersistChapterProgress(
  existing: ReadingHistoryEntry | null,
  incoming: ReadingInfo,
): boolean {
  if (!existing) return true;

  const existingPart = resolveStoryPartKey(existing.metadata);
  const incomingPart = resolveStoryPartKey(incoming.metadata);
  if (existingPart !== incomingPart) return true;

  const existingRank = resolveChapterRank(toRankSource(existing));
  const incomingRank = resolveChapterRank(incoming);

  if (existingRank != null && incomingRank != null) {
    return incomingRank >= existingRank;
  }
  if (incomingRank != null && existingRank == null) return true;
  if (incomingRank == null && existingRank != null) return false;

  return incoming.progress.percentage >= existing.progress.percentage;
}
