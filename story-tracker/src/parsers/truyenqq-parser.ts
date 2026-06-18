import { BaseParser } from './base-parser';
import type { ParserContext } from '../types/parser';
import type { ReadingInfo } from '../types/reading';

export class TruyenQQParser extends BaseParser {
  readonly siteId = 'truyenqq';
  readonly priority = 100;

  canHandle(url: string): boolean {
    return /truyenqq/i.test(url);
  }

  async extract(): Promise<ReadingInfo> {
    const breadcrumbs = this.getBreadcrumbTexts();
    const titleInfo = this.extractFromTitle();

    const storyTitle =
      this.getText('.story-name') ??
      this.getText('.book-name') ??
      this.getText('.title') ??
      breadcrumbs[breadcrumbs.length - 2] ??
      titleInfo.storyTitle;

    const chapterTitle =
      this.getText('.chapter-name') ??
      this.getText('.chapter-title') ??
      this.getText('h1') ??
      breadcrumbs[breadcrumbs.length - 1] ??
      titleInfo.chapterTitle;

    const storyId = this.extractStorySlug();
    const chapterId = this.extractChapterNumber();

    return this.buildReadingInfo({
      storyId: storyId ?? undefined,
      storyTitle,
      chapterId,
      chapterTitle,
      metadata: { parser: this.siteId, site: 'truyenqq' },
    });
  }

  private extractStorySlug(): string | undefined {
    const match = this.ctx.url.match(/truyen-tranh\/([^/]+)/i);
    return match?.[1];
  }

  private extractChapterNumber(): string | undefined {
    const match = this.ctx.url.match(/chuong-(\d+)/i);
    return match?.[1];
  }
}

export function createTruyenQQParser(ctx: ParserContext): TruyenQQParser {
  return new TruyenQQParser(ctx);
}
