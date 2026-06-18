import { BaseParser } from './base-parser';
import type { ParserContext } from '../types/parser';
import type { ReadingInfo } from '../types/reading';

export class VietnamThuQuanParser extends BaseParser {
  readonly siteId = 'vietnamthuquan';
  readonly priority = 100;

  canHandle(url: string): boolean {
    return /thuquansach|vietnamthuquan/i.test(url);
  }

  async extract(): Promise<ReadingInfo> {
    const breadcrumbs = this.getBreadcrumbTexts();
    const titleInfo = this.extractFromTitle();
    const navChapter = this.getChapterFromNav();

    const storyTitle =
      this.getText('.book-title') ??
      this.getText('.story-title') ??
      this.getText('h1.title') ??
      breadcrumbs[breadcrumbs.length - 2] ??
      titleInfo.storyTitle;

    const chapterTitle =
      this.getText('.chapter-title') ??
      this.getText('.chapter-heading') ??
      this.getText('h2') ??
      navChapter.chapterTitle ??
      breadcrumbs[breadcrumbs.length - 1] ??
      titleInfo.chapterTitle;

    const storyId = this.extractStoryId();
    const chapterId = this.extractChapterId() ?? navChapter.chapterId;

    return this.buildReadingInfo({
      storyId: storyId ?? undefined,
      storyTitle,
      chapterId,
      chapterTitle,
      metadata: { parser: this.siteId, site: 'vietnamthuquan' },
    });
  }

  private extractStoryId(): string | undefined {
    const match = this.ctx.url.match(/(?:truyen|book|story)\/([^/]+)/i);
    return match?.[1];
  }

  private extractChapterId(): string | undefined {
    const match = this.ctx.url.match(/(?:chuong|chapter)\/([^/]+)/i);
    return match?.[1];
  }
}

export function createVietnamThuQuanParser(ctx: ParserContext): VietnamThuQuanParser {
  return new VietnamThuQuanParser(ctx);
}
