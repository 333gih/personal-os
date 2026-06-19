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
    const readerMeta = this.extractReaderMeta();

    const storyTitle =
      this.getText('.book-title') ??
      this.getText('.story-title') ??
      this.getText('h1.title') ??
      this.getText('#title, #TenTruyen, .ten-truyen') ??
      breadcrumbs[breadcrumbs.length - 2] ??
      titleInfo.storyTitle;

    const chapterTitle =
      this.getText('.chapter-title') ??
      this.getText('.chapter-heading') ??
      this.getText('#TenChuong, .ten-chuong') ??
      this.getText('h2') ??
      navChapter.chapterTitle ??
      readerMeta.chapterTitle ??
      breadcrumbs[breadcrumbs.length - 1] ??
      titleInfo.chapterTitle;

    const storyId = this.extractStoryId();
    const chapterId = this.extractChapterId() ?? navChapter.chapterId;

    return this.buildReadingInfo({
      storyId: storyId ?? undefined,
      storyTitle,
      chapterId,
      chapterTitle,
      metadata: {
        parser: this.siteId,
        site: 'vietnamthuquan',
        page_kind: 'chapter',
      },
    });
  }

  private extractReaderMeta(): { chapterId?: string; chapterTitle?: string } {
    try {
      const parsed = new URL(this.ctx.url);
      const hash = parsed.hash.replace(/^#/, '').trim();
      if (!hash) return {};

      if (/^phandau$/i.test(hash)) {
        return { chapterId: hash, chapterTitle: 'Phần đầu' };
      }
      const phanMatch = hash.match(/^phan(\d+)$/i);
      if (phanMatch) {
        return { chapterId: hash, chapterTitle: `Phần ${phanMatch[1]}` };
      }
      return { chapterId: hash, chapterTitle: hash };
    } catch {
      return {};
    }
  }

  private extractStoryId(): string | undefined {
    try {
      const parsed = new URL(this.ctx.url);
      const tid = parsed.searchParams.get('tid')?.trim();
      if (tid) return tid;
    } catch {
      /* fall through */
    }

    const match = this.ctx.url.match(/(?:truyen|book|story)\/([^/?#]+)/i);
    const slug = match?.[1];
    if (slug && !/\.aspx$/i.test(slug)) return slug;
    return undefined;
  }

  private extractChapterId(): string | undefined {
    const readerMeta = this.extractReaderMeta();
    if (readerMeta.chapterId) return readerMeta.chapterId;

    const match = this.ctx.url.match(/(?:chuong|chapter)\/([^/]+)/i);
    return match?.[1];
  }
}

export function createVietnamThuQuanParser(ctx: ParserContext): VietnamThuQuanParser {
  return new VietnamThuQuanParser(ctx);
}
