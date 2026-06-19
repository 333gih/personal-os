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

  it('detects Vietnam Thu Quan truyen.aspx reader URLs', () => {
    const url =
      'http://vietnamthuquan.eu/truyen/truyen.aspx?tid=2qtqv3m3237nnnnn0n4nnn31n343tq83a3q3m3237nvn#phandau';
    const result = classifyReadingPage(url);
    expect(result.kind).toBe('chapter');
    expect(result.storySlug).toBe('2qtqv3m3237nnnnn0n4nnn31n343tq83a3q3m3237nvn');
    expect(result.chapterId).toBe('phandau');
    expect(result.chapterTitle).toBe('Phần đầu');
    expect(isChapterPage(url)).toBe(true);
  });

  it('detects Vietnam Thu Quan reader without hash', () => {
    const url =
      'https://vietnamthuquan.com/truyen/truyen.aspx?tid=abc123&AspxAutoDetectCookieSupport=1';
    const result = classifyReadingPage(url);
    expect(result.kind).toBe('chapter');
    expect(result.chapterId).toBe('reader');
    expect(isChapterPage(url)).toBe(true);
  });
});
