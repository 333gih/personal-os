import { describe, it, expect } from 'vitest';
import { ParserFactoryRegistry, extractReadingInfo } from './parser-factory';
import { createGenericParser } from './generic-parser';
import { createTruyenFullParser } from './truyenfull-parser';
import type { ParserContext } from '../types/parser';

function createContext(html: string, url: string): ParserContext {
  const dom = new DOMParser().parseFromString(html, 'text/html');
  return {
    document: dom,
    window: { scrollY: 0, innerHeight: 800 } as unknown as Window,
    url,
  };
}

const TRUYENFULL_CHAPTER_HTML = `
<html>
  <head>
    <title>Xuyên Thành Thế Thân Tình Nhân Của Boss Phản Diện : Chương 26 - Truyenfull.vn</title>
  </head>
  <body>
    <h1 class="title">Xuyên Thành Thế Thân Tình Nhân Của Boss Phản Diện</h1>
    <h2>Chương 26</h2>
    <div id="chapter-content">Nội dung chương...</div>
  </body>
</html>
`;

describe('ParserFactoryRegistry', () => {
  it('resolves NetTruyen parser for nettruyen URLs', () => {
    const registry = new ParserFactoryRegistry();
    const ctx = createContext('<html><body></body></html>', 'https://nettruyen.com/truyen-tranh/one-piece/chuong-1');
    const parser = registry.resolve(ctx);
    expect(parser.siteId).toBe('nettruyen');
  });

  it('resolves TruyenFull parser for truyenfull URLs', () => {
    const registry = new ParserFactoryRegistry();
    const ctx = createContext(
      TRUYENFULL_CHAPTER_HTML,
      'https://truyenfull.today/xuyen-thanh-the-than-tinh-nhan-cua-boss-phan-dien/chuong-26/',
    );
    const parser = registry.resolve(ctx);
    expect(parser.siteId).toBe('truyenfull');
  });

  it('falls back to generic parser for unknown sites', () => {
    const registry = new ParserFactoryRegistry();
    const ctx = createContext(
      '<html><head><title>Chapter 5 - My Story</title></head><body><h1>Chapter 5</h1></body></html>',
      'https://unknown-site.com/read/123',
    );
    const parser = registry.resolve(ctx);
    expect(parser.siteId).toBe('generic');
  });
});

describe('extractReadingInfo', () => {
  it('returns null for truyenfull home page', async () => {
    const info = await extractReadingInfo(
      createContext('<html><body></body></html>', 'https://truyenfull.today/'),
    );
    expect(info).toBeNull();
  });
});

describe('GenericParser', () => {
  it('extracts title from document.title', async () => {
    const ctx = createContext(
      '<html><head><title>Chapter 3 - Test Story</title></head><body></body></html>',
      'https://example.com/chuong-3/',
    );
    const parser = createGenericParser(ctx);
    const info = await parser.extract();
    expect(info.storyTitle).toBe('Test Story');
    expect(info.chapterTitle).toBe('Chương 3');
  });
});

describe('TruyenFullParser', () => {
  it('extracts story and chapter from truyenfull chapter URL', async () => {
    const ctx = createContext(
      TRUYENFULL_CHAPTER_HTML,
      'https://truyenfull.today/xuyen-thanh-the-than-tinh-nhan-cua-boss-phan-dien/chuong-26/',
    );
    const parser = createTruyenFullParser(ctx);
    const info = await parser.extract();

    expect(info.storyId).toBe('xuyen-thanh-the-than-tinh-nhan-cua-boss-phan-dien');
    expect(info.storyTitle).toBe('Xuyên Thành Thế Thân Tình Nhân Của Boss Phản Diện');
    expect(info.chapterId).toBe('26');
    expect(info.chapterTitle).toBe('Chương 26');
    expect(info.metadata?.parser).toBe('truyenfull');
  });
});
