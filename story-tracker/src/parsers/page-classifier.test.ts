import { describe, expect, it } from 'vitest';
import { classifyReadingPage, isChapterPage } from './page-classifier';

describe('page-classifier', () => {
  it('detects truyenfull chapter URLs', () => {
    const result = classifyReadingPage(
      'https://truyenfull.today/xuyen-thanh-the-than-tinh-nhan-cua-boss-phan-dien/chuong-26/',
    );
    expect(result.kind).toBe('chapter');
    expect(result.chapterId).toBe('26');
    expect(result.storySlug).toBe('xuyen-thanh-the-than-tinh-nhan-cua-boss-phan-dien');
  });

  it('treats truyenfull home as listing', () => {
    expect(classifyReadingPage('https://truyenfull.today/').kind).toBe('listing');
    expect(isChapterPage('https://truyenfull.today/')).toBe(false);
  });

  it('treats story index without chapter as story_home', () => {
    expect(
      classifyReadingPage('https://truyenfull.today/xuyen-thanh-the-than-tinh-nhan-cua-boss-phan-dien/')
        .kind,
    ).toBe('story_home');
  });
});
