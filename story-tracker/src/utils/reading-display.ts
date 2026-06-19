import type { ReadingHistoryEntry, ReadingInfo } from '../types/reading';

/** Popup/history display — respects site-specific display_format metadata. */
export function formatChapterDisplay(info: ReadingInfo): string {
  const format = info.metadata?.display_format;
  const chapterNumber = info.metadata?.chapter_number ?? info.metadata?.chapter_index;
  const total = info.metadata?.total_chapters;

  if (format === 'chapter_of_total' && chapterNumber) {
    if (total) return `Chương ${chapterNumber} / ${total}`;
    return `Chương ${chapterNumber}`;
  }

  const title = info.chapterTitle?.trim();
  if (!title) return 'Current chapter';
  if (isNoisyDisplayText(title) && chapterNumber) {
    return total ? `Chương ${chapterNumber} / ${total}` : `Chương ${chapterNumber}`;
  }
  return title;
}

export function formatPartLabel(info: ReadingInfo): string | null {
  const part = info.metadata?.part_title;
  return typeof part === 'string' && part.trim() ? part.trim() : null;
}

/** Map a stored history row to ReadingInfo for consistent chapter labels. */
export function historyEntryToReadingInfo(entry: ReadingHistoryEntry): ReadingInfo {
  if (entry.metadata) {
    return {
      storyId: entry.storyId,
      storyTitle: entry.storyTitle,
      chapterId: entry.chapterId,
      chapterTitle: entry.chapterTitle,
      currentUrl: entry.currentUrl,
      progress: entry.progress,
      metadata: entry.metadata,
    };
  }

  const chapterFromId = entry.chapterId?.match(/chuong-(\d+)/i)?.[1];
  const chapterFromTitle = entry.chapterTitle?.match(/chương\s*(\d+)/i)?.[1];
  const isVtq = entry.siteId === 'vietnamthuquan';

  return {
    storyId: entry.storyId,
    storyTitle: entry.storyTitle,
    chapterId: entry.chapterId,
    chapterTitle: entry.chapterTitle,
    currentUrl: entry.currentUrl,
    progress: entry.progress,
    metadata: {
      chapter_number: chapterFromId ?? chapterFromTitle,
      display_format: isVtq ? 'chapter_of_total' : 'default',
    },
  };
}

function isNoisyDisplayText(text: string): boolean {
  if (text.length > 80) return true;
  if (/cỡ chữ/i.test(text)) return true;
  if (/mục lục/i.test(text) && /chương\s*\d+/i.test(text)) return true;
  if ((text.match(/chương\s*\d+/gi) || []).length > 1) return true;
  return false;
}
