import { describe, expect, it } from 'vitest';
import type { ReadingHistoryEntry, ReadingInfo } from '../types/reading';
import { resolveChapterRank, shouldPersistChapterProgress } from './chapter-progress';

const baseInfo = (overrides: Partial<ReadingInfo> = {}): ReadingInfo => ({
  storyId: 'story-1',
  storyTitle: 'Test Story',
  currentUrl: 'https://example.com/chuong-10',
  progress: { percentage: 10, scrollY: 0, readingTimeSeconds: 0 },
  ...overrides,
});

const baseEntry = (overrides: Partial<ReadingHistoryEntry> = {}): ReadingHistoryEntry => ({
  storyId: 'story-1',
  storyTitle: 'Test Story',
  currentUrl: 'https://example.com/chuong-50',
  progress: { percentage: 50, scrollY: 0, readingTimeSeconds: 120 },
  lastReadAt: Date.now(),
  siteId: 'truyenfull',
  metadata: { chapter_number: '50', chapter_index: 50 },
  ...overrides,
});

describe('chapter-progress', () => {
  it('resolves chapter rank from metadata and ids', () => {
    expect(
      resolveChapterRank({
        chapterId: 'chuong-26',
        metadata: { chapter_index: 26, chapter_number: '26' },
      }),
    ).toBe(26);

    expect(
      resolveChapterRank({
        chapterTitle: 'Chương 103 / 200',
        metadata: { chuongid: '33083' },
      }),
    ).toBe(33083);
  });

  it('allows first save and higher chapter updates', () => {
    const incoming = baseInfo({
      metadata: { chapter_number: '60', chapter_index: 60 },
      progress: { percentage: 60, scrollY: 0, readingTimeSeconds: 0 },
    });

    expect(shouldPersistChapterProgress(null, incoming)).toBe(true);
    expect(shouldPersistChapterProgress(baseEntry(), incoming)).toBe(true);
  });

  it('blocks lower chapter from overwriting stored progress', () => {
    const incoming = baseInfo({
      metadata: { chapter_number: '12', chapter_index: 12 },
      progress: { percentage: 12, scrollY: 0, readingTimeSeconds: 0 },
    });

    expect(shouldPersistChapterProgress(baseEntry(), incoming)).toBe(false);
  });

  it('allows same chapter refresh', () => {
    const incoming = baseInfo({
      metadata: { chapter_number: '50', chapter_index: 50 },
      progress: { percentage: 55, scrollY: 400, readingTimeSeconds: 30 },
    });

    expect(shouldPersistChapterProgress(baseEntry(), incoming)).toBe(true);
  });

  it('treats different story parts independently', () => {
    const existing = baseEntry({ metadata: { chapter_number: '90', chapter_index: 90, part_id: 'phan-a' } });
    const incoming = baseInfo({
      metadata: { chapter_number: '3', chapter_index: 3, part_id: 'phan-b' },
    });

    expect(shouldPersistChapterProgress(existing, incoming)).toBe(true);
  });
});
