import { BaseParser } from './base-parser';
import type { ParserContext } from '../types/parser';
import type { ReadingInfo } from '../types/reading';
import { getHostname } from '../utils/url';
import { createStoryFingerprint } from '../utils/fingerprint';

export class GenericParser extends BaseParser {
  readonly siteId = 'generic';
  readonly priority = 0;

  canHandle(): boolean {
    return true;
  }

  async extract(): Promise<ReadingInfo> {
    const urlMeta = this.extractUrlMetadata();
    const domMeta = this.extractDomMetadata();
    const breadcrumbs = this.getBreadcrumbTexts();
    const navChapter = this.getChapterFromNav();
    const titleMeta = this.extractFromTitle();
    const ogTitle = this.getMeta('og:title');

    const storyTitle =
      urlMeta.storyTitle ??
      domMeta.storyTitle ??
      (breadcrumbs.length > 1 ? breadcrumbs[breadcrumbs.length - 2] : undefined) ??
      ogTitle ??
      titleMeta.storyTitle ??
      getHostname(this.ctx.url);

    const chapterTitle =
      urlMeta.chapterTitle ??
      domMeta.chapterTitle ??
      navChapter.chapterTitle ??
      (breadcrumbs.length > 0 ? breadcrumbs[breadcrumbs.length - 1] : undefined) ??
      titleMeta.chapterTitle;

    const storyId =
      urlMeta.storyId ?? (await createStoryFingerprint(storyTitle, this.ctx.url));

    return this.buildReadingInfo({
      storyId,
      storyTitle,
      chapterId: urlMeta.chapterId ?? navChapter.chapterId,
      chapterTitle,
      metadata: {
        parser: this.siteId,
        breadcrumbs,
        source: this.resolveSource(urlMeta, domMeta, breadcrumbs, titleMeta),
      },
    });
  }

  private extractUrlMetadata(): {
    storyId?: string;
    storyTitle?: string;
    chapterId?: string;
    chapterTitle?: string;
  } {
    try {
      const url = new URL(this.ctx.url);
      const parts = url.pathname.split('/').filter(Boolean);

      const chapterPatterns = /^(chuong|chapter|chap|ep|tap)-?(\d+)/i;
      const storyPatterns = /^(truyen|story|manga|comic|book)-?(.+)/i;

      let storyTitle: string | undefined;
      let chapterTitle: string | undefined;
      let chapterId: string | undefined;
      let storyId: string | undefined;

    for (const part of parts) {
      const chapterMatch = part.match(chapterPatterns);
      if (chapterMatch) {
        chapterId = chapterMatch[2];
        chapterTitle = `Chương ${chapterMatch[2]}`;
        continue;
      }
      const slugChapterMatch = part.match(/^chuong-(\d+(?:\.\d+)?)$/i);
      if (slugChapterMatch) {
        chapterId = slugChapterMatch[1];
        chapterTitle = `Chương ${slugChapterMatch[1]}`;
        continue;
      }
        const storyMatch = part.match(storyPatterns);
        if (storyMatch) {
          storyId = storyMatch[2];
          storyTitle = decodeURIComponent(storyMatch[2].replace(/-/g, ' '));
        }
      }

      if (parts.length >= 2 && !storyId) {
        const chapterPart = parts[parts.length - 1];
        if (/^chuong-\d/i.test(chapterPart)) {
          storyId = parts[parts.length - 2];
          storyTitle = decodeURIComponent(parts[parts.length - 2].replace(/-/g, ' '));
        }
      }

      return { storyId, storyTitle, chapterId, chapterTitle };
    } catch {
      return {};
    }
  }

  private extractDomMetadata(): { storyTitle?: string; chapterTitle?: string } {
    const storyTitle =
      this.getText('h1.story-title') ??
      this.getText('.story-name') ??
      this.getText('.book-title') ??
      this.getText('h1');

    const chapterTitle =
      this.getText('.chapter-title') ??
      this.getText('.chapter-name') ??
      this.getText('h2.chapter-title') ??
      this.getText('.reading-detail h2');

    return { storyTitle, chapterTitle };
  }

  private resolveSource(
    urlMeta: Record<string, unknown>,
    domMeta: Record<string, unknown>,
    breadcrumbs: string[],
    titleMeta: Record<string, unknown>,
  ): string {
    if (Object.keys(urlMeta).length > 0) return 'url';
    if (Object.keys(domMeta).some((k) => domMeta[k])) return 'dom';
    if (breadcrumbs.length > 0) return 'breadcrumbs';
    if (titleMeta.chapterTitle) return 'title';
    return 'scroll-fallback';
  }
}

export function createGenericParser(ctx: ParserContext): GenericParser {
  return new GenericParser(ctx);
}
