import { describe, it, expect } from 'vitest';
import { ParserFactoryRegistry } from './parser-factory';
import { createGenericParser } from './generic-parser';
import type { ParserContext } from '../types/parser';

function createContext(html: string, url: string): ParserContext {
  const dom = new DOMParser().parseFromString(html, 'text/html');
  return {
    document: dom,
    window: { scrollY: 0, innerHeight: 800 } as unknown as Window,
    url,
  };
}

describe('ParserFactoryRegistry', () => {
  it('resolves NetTruyen parser for nettruyen URLs', () => {
    const registry = new ParserFactoryRegistry();
    const ctx = createContext('<html><body></body></html>', 'https://nettruyen.com/truyen-tranh/one-piece/chuong-1');
    const parser = registry.resolve(ctx);
    expect(parser.siteId).toBe('nettruyen');
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

describe('GenericParser', () => {
  it('extracts title from document.title', async () => {
    const ctx = createContext(
      '<html><head><title>Chapter 3 - Test Story</title></head><body></body></html>',
      'https://example.com/page',
    );
    const parser = createGenericParser(ctx);
    const info = await parser.extract();
    expect(info.storyTitle).toBe('Test Story');
    expect(info.chapterTitle).toBe('Chapter 3');
  });
});
