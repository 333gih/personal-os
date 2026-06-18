import { BaseParser } from './base-parser';
import type { ParserContext } from '../types/parser';
import type { ReadingInfo } from '../types/reading';

export class NetTruyenParser extends BaseParser {
  readonly siteId = 'nettruyen';
  readonly priority = 100;

  canHandle(url: string): boolean {
    return /nettruyen/i.test(url);
  }

  async extract(): Promise<ReadingInfo> {
    const breadcrumbs = this.getBreadcrumbTexts();
    const titleInfo = this.extractFromTitle();

    const storyTitle =
      this.getText('.title-detail') ??
      this.getText('.story-detail h1') ??
      breadcrumbs[breadcrumbs.length - 2] ??
      titleInfo.storyTitle;

    const chapterTitle =
      this.getText('.chapter-title') ??
      this.getText('h1') ??
      breadcrumbs[breadcrumbs.length - 1] ??
      titleInfo.chapterTitle;

    const storyId = this.extractStoryIdFromUrl() ?? this.getText('.title-detail a')?.toLowerCase();
    const chapterId = this.extractChapterIdFromUrl();

    return this.buildReadingInfo({
      storyId: storyId ?? undefined,
      storyTitle,
      chapterId,
      chapterTitle,
      metadata: { parser: this.siteId, site: 'nettruyen' },
    });
  }

  private extractStoryIdFromUrl(): string | undefined {
    const match = this.ctx.url.match(/truyen-tranh\/([^/]+)/i);
    return match?.[1];
  }

  private extractChapterIdFromUrl(): string | undefined {
    const match = this.ctx.url.match(/chuong-(\d+)/i);
    return match?.[1];
  }
}

export function createNetTruyenParser(ctx: ParserContext): NetTruyenParser {
  return new NetTruyenParser(ctx);
}
