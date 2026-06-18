import { BaseParser } from './base-parser';
import type { ParserContext } from '../types/parser';
import type { ReadingInfo } from '../types/reading';

export class TruyenFullParser extends BaseParser {
  readonly siteId = 'truyenfull';
  readonly priority = 100;

  canHandle(url: string): boolean {
    return /truyenfull/i.test(url);
  }

  async extract(): Promise<ReadingInfo> {
    const urlMeta = this.extractFromUrl();
    const titleMeta = this.extractFromTruyenFullTitle();
    const breadcrumbs = this.getBreadcrumbTexts();

    const storyTitle =
      this.getText('.book-title') ??
      this.getText('.title a') ??
      this.getText('.truyen-title') ??
      this.getText('h1.title') ??
      breadcrumbs.find((t) => !/^chương\s+\d/i.test(t) && !/^truyện$/i.test(t)) ??
      titleMeta.storyTitle ??
      urlMeta.storyTitle;

    const chapterTitle =
      this.getText('.chapter-title') ??
      this.getText('#chapter-heading') ??
      this.getText('.chapter h2') ??
      this.getText('h2') ??
      breadcrumbs.find((t) => /^chương\s+\d/i.test(t)) ??
      titleMeta.chapterTitle ??
      urlMeta.chapterTitle;

    return this.buildReadingInfo({
      storyId: urlMeta.storyId,
      storyTitle: storyTitle ?? 'Unknown story',
      chapterId: urlMeta.chapterId,
      chapterTitle,
      metadata: { parser: this.siteId, site: 'truyenfull' },
    });
  }

  private extractFromUrl(): {
    storyId?: string;
    storyTitle?: string;
    chapterId?: string;
    chapterTitle?: string;
  } {
    try {
      const parts = new URL(this.ctx.url).pathname.split('/').filter(Boolean);
      if (parts.length < 2) return {};

      const storySlug = parts[0];
      const chapterSegment = parts[1];
      const chapterMatch = chapterSegment.match(/^chuong-(\d+(?:\.\d+)?)$/i);
      if (!chapterMatch) return { storyId: storySlug };

      const chapterId = chapterMatch[1];
      return {
        storyId: storySlug,
        storyTitle: decodeURIComponent(storySlug.replace(/-/g, ' ')),
        chapterId,
        chapterTitle: `Chương ${chapterId}`,
      };
    } catch {
      return {};
    }
  }

  private extractFromTruyenFullTitle(): { storyTitle?: string; chapterTitle?: string } {
    const title = this.ctx.document.title;
    const match = title.match(/^(.+?)\s*:\s*(Chương\s+[\d.]+)/i);
    if (!match) return {};

    return {
      storyTitle: match[1].trim(),
      chapterTitle: match[2].trim(),
    };
  }
}

export function createTruyenFullParser(ctx: ParserContext): TruyenFullParser {
  return new TruyenFullParser(ctx);
}
