import { describe, expect, it } from 'vitest';
import { formatChapterDisplay, historyEntryToReadingInfo } from './reading-display';
import type { ReadingHistoryEntry, ReadingInfo } from '../types/reading';

describe('reading-display', () => {
  it('shows chapter_of_total for VTQ metadata', () => {
    const info: ReadingInfo = {
      storyId: 'abc',
      storyTitle: 'Test',
      currentUrl: 'http://example.com',
      progress: { percentage: 40, scrollY: 0, readingTimeSeconds: 0 },
      metadata: {
        display_format: 'chapter_of_total',
        chapter_number: '5',
        total_chapters: 200,
      },
    };
    expect(formatChapterDisplay(info)).toBe('Chương 5 / 200');
  });

  it('falls back when chapter title is noisy UI text', () => {
    const info: ReadingInfo = {
      storyId: 'abc',
      storyTitle: 'Test',
      chapterTitle:
        'Phần đầu — A+ A- Cỡ chữ 16 Mục Lục Chương 1 Chương 2 Chương 3',
      currentUrl: 'http://example.com',
      progress: { percentage: 0, scrollY: 0, readingTimeSeconds: 0 },
      metadata: { chapter_number: '7', total_chapters: 120 },
    };
    expect(formatChapterDisplay(info)).toBe('Chương 7 / 120');
  });

  it('cleans legacy VTQ history rows without metadata', () => {
    const entry: ReadingHistoryEntry = {
      storyId: 'vtq-1',
      storyTitle: 'Thiên Tài Tiên Đạo',
      chapterTitle: 'Chương 1 Tiến >>',
      currentUrl: 'http://vietnamthuquan.eu/foo#phandau',
      progress: { percentage: 0, scrollY: 0, readingTimeSeconds: 0 },
      lastReadAt: Date.now(),
      siteId: 'vietnamthuquan',
    };
    expect(formatChapterDisplay(historyEntryToReadingInfo(entry))).toBe('Chương 1');
  });
});
