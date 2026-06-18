import type { ParserContext, StoryParser } from '../types/parser';
import type { ReadingInfo } from '../types/reading';
import { createStoryFingerprint, createUrlHash } from '../utils/fingerprint';
import { normalizeUrl } from '../utils/url';

export abstract class BaseParser implements StoryParser {
  abstract readonly siteId: string;
  abstract readonly priority: number;

  constructor(protected readonly ctx: ParserContext) {}

  abstract canHandle(url: string): boolean;
  abstract extract(): Promise<ReadingInfo>;

  protected getScrollProgress(): { percentage: number; scrollY: number } {
    const { document, window } = this.ctx;
    const contentRoot =
      document.querySelector<HTMLElement>(
        '#chapter-content, .chapter-c, .chapter-content, .reading-content, .content-chapter, .truyen',
      ) ?? document.documentElement;

    const scrollY = window.scrollY;
    const viewportBottom = scrollY + window.innerHeight;
    const contentTop = contentRoot.getBoundingClientRect().top + scrollY;
    const contentHeight = contentRoot.scrollHeight;
    const readableHeight = Math.max(contentHeight, 1);
    const readThrough = Math.max(0, viewportBottom - contentTop);
    const percentage = Math.min(100, Math.round((readThrough / readableHeight) * 100));

    return { percentage, scrollY };
  }

  protected getText(selector: string): string | undefined {
    const el = this.ctx.document.querySelector(selector);
    return el?.textContent?.trim() || undefined;
  }

  protected getMeta(property: string): string | undefined {
    const el = this.ctx.document.querySelector(
      `meta[property="${property}"], meta[name="${property}"]`,
    );
    return el?.getAttribute('content')?.trim() || undefined;
  }

  protected getBreadcrumbTexts(): string[] {
    const selectors = [
      '.breadcrumb a',
      '.breadcrumbs a',
      'nav[aria-label="breadcrumb"] a',
      '[itemtype*="BreadcrumbList"] a',
      '.breadcrumb li',
    ];

    for (const selector of selectors) {
      const items = Array.from(this.ctx.document.querySelectorAll(selector))
        .map((el) => el.textContent?.trim())
        .filter((t): t is string => Boolean(t));
      if (items.length > 0) return items;
    }
    return [];
  }

  protected getChapterFromNav(): { chapterId?: string; chapterTitle?: string } {
    const current = this.ctx.document.querySelector(
      '.chapter-nav .active, .nav-chapter .active, .pagination .active, .page-item.active',
    );
    if (current) {
      return {
        chapterTitle: current.textContent?.trim(),
        chapterId: current.getAttribute('href') ?? current.getAttribute('data-id') ?? undefined,
      };
    }
    return {};
  }

  protected async buildReadingInfo(partial: {
    storyId?: string;
    storyTitle: string;
    chapterId?: string;
    chapterTitle?: string;
    readingTimeSeconds?: number;
    metadata?: Record<string, unknown>;
  }): Promise<ReadingInfo> {
    const { percentage, scrollY } = this.getScrollProgress();
    const url = normalizeUrl(this.ctx.url);

    const storyId =
      partial.storyId ??
      (await createStoryFingerprint(partial.storyTitle, url, partial.metadata));

    const chapterId =
      partial.chapterId ??
      (partial.chapterTitle ? createUrlHash(`${storyId}:${partial.chapterTitle}`) : createUrlHash(url));

    return {
      storyId,
      storyTitle: partial.storyTitle,
      chapterId,
      chapterTitle: partial.chapterTitle,
      currentUrl: this.ctx.url,
      progress: {
        percentage,
        scrollY,
        readingTimeSeconds: partial.readingTimeSeconds ?? 0,
      },
      metadata: partial.metadata,
    };
  }

  protected extractFromTitle(): { storyTitle: string; chapterTitle?: string } {
    const title = this.ctx.document.title;
    const separators = [' - ', ' | ', ' — ', ' » ', ' > '];
    for (const sep of separators) {
      if (title.includes(sep)) {
        const parts = title.split(sep).map((p) => p.trim()).filter(Boolean);
        if (parts.length >= 2) {
          return { chapterTitle: parts[0], storyTitle: parts[parts.length - 1] };
        }
      }
    }
    return { storyTitle: title };
  }
}
