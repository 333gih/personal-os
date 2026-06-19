import { BaseParser } from './base-parser';
import type { ParserContext } from '../types/parser';
import type { ReadingInfo } from '../types/reading';
import type { SiteProfile } from '../types/site-profile';
import { matchProfile, getBuiltinProfiles } from '../config/site-profile-builtin';
import {
  crawlChapterMeta,
  crawlStoryMeta,
  crawlVtqSyncMeta,
  getScrollRoot,
  getChapterBoundedProgress,
  isNoisyChapterText,
} from './dom-crawler';
import { applySitePlugin } from '../plugins/apply';
import { isNavigationNoiseTitle, readVtqStoryTitle } from '../plugins/builtin/vietnamthuquan/muluben';
import { extractUrlHashId, formatHashChapterTitle, isPartHashId } from './url-detector';
import { createStoryFingerprint, createUrlHash } from '../utils/fingerprint';
import { normalizeUrl } from '../utils/url';

export class ProfileParser extends BaseParser {
  readonly siteId: string;
  readonly priority: number;

  constructor(
    ctx: ParserContext,
    private readonly profile: SiteProfile,
  ) {
    super(ctx);
    this.siteId = profile.id;
    this.priority = profile.priority ?? 100;
  }

  canHandle(url: string): boolean {
    return matchProfile(url, [this.profile]) !== null;
  }

  async extract(): Promise<ReadingInfo> {
    const crawlCtx = {
      document: this.ctx.document,
      window: this.ctx.window,
      url: this.ctx.url,
      chapterHint: this.ctx.chapterHint,
    };

    const storyMeta = crawlStoryMeta(
      crawlCtx,
      this.profile.selectors,
      this.profile.urlRules.queryParams?.story,
    );

    const chapterMeta =
      this.ctx.syncMode && this.profile.extension?.handler === 'vietnamthuquan'
        ? crawlVtqSyncMeta(crawlCtx, this.profile.selectors)
        : crawlChapterMeta(
            crawlCtx,
            this.profile.selectors,
            this.profile.chapterDetection,
            this.profile.urlRules.queryParams,
          );

    const rawStoryTitle =
      storyMeta.storyTitle ??
      normalizeStoryTitleCandidate(this.ctx.document.title.split(/ [-|—] /)[0]?.trim()) ??
      'Unknown story';

    const storyTitle =
      this.profile.extension?.handler === 'vietnamthuquan'
        ? readVtqStoryTitle(
            this.ctx.document,
            this.profile.extension?.fields?.storyTitle ?? 'span.chuto40, .chuto40',
          ) ?? (isNavigationNoiseTitle(rawStoryTitle) ? 'Unknown story' : rawStoryTitle)
        : rawStoryTitle;

    const partId = extractUrlHashId(this.ctx.url);
    const partTitle =
      partId && isPartHashId(partId)
        ? formatHashChapterTitle(partId)
        : chapterMeta.partTitle;

    const usesSiteHandler = Boolean(this.profile.extension?.handler);

    let chapterTitle = chapterMeta.chapterTitle;
    if (!usesSiteHandler) {
      if (partTitle && chapterTitle && !chapterTitle.toLowerCase().includes(partTitle.toLowerCase())) {
        chapterTitle = `${partTitle} — ${chapterTitle}`;
      } else if (!chapterTitle && partTitle && !isPartHashId(partId ?? '')) {
        chapterTitle = partTitle;
      }
    } else if (chapterTitle && isNoisyChapterText(chapterTitle)) {
      chapterTitle = undefined;
    }

    const storyId =
      storyMeta.storyId ??
      (await createStoryFingerprint(storyTitle, this.ctx.url, { parser: this.siteId }));

    const partOnly = Boolean(partId && isPartHashId(partId) && !chapterMeta.chapterTitle);
    const chapterId =
      chapterMeta.chapterId ??
      (partOnly && partId
        ? `${partId}:part`
        : chapterTitle
          ? createUrlHash(`${storyId}:${chapterTitle}`)
          : 'reader');

    const currentUrl = chapterMeta.chapterUrl
      ? normalizeUrl(chapterMeta.chapterUrl)
      : normalizeUrl(this.ctx.url);

    const bounded = getChapterBoundedProgress(crawlCtx, this.profile.selectors, chapterMeta);
    const { percentage, scrollY } =
      bounded ?? this.getScrollProgressForProfile();

    const base: ReadingInfo = {
      storyId,
      storyTitle,
      chapterId,
      chapterTitle,
      currentUrl,
      progress: {
        percentage,
        scrollY,
        readingTimeSeconds: 0,
      },
      metadata: {
        parser: this.siteId,
        profile: this.profile.id,
        page_kind: 'chapter',
        chapter_source: chapterMeta.source,
        story_source: storyMeta.source,
        part_id: partId ?? chapterMeta.partId,
        part_title: usesSiteHandler ? partTitle : undefined,
        part_only: partOnly,
        chapter_number: chapterMeta.chapterId?.match(/chuong-(\d+)/i)?.[1] ??
          this.ctx.chapterHint?.chapterNumber ??
          (chapterMeta.chapterIndex ? String(chapterMeta.chapterIndex) : undefined),
        total_chapters: chapterMeta.totalChapters,
        chapter_index: chapterMeta.chapterIndex,
        chapter_anchor: chapterMeta.chapterUrl?.split('#')[1],
      },
    };

    const handler = this.profile.extension?.handler;
    if (handler) {
      return applySitePlugin({
        ctx: this.ctx,
        profile: this.profile,
        extension: this.profile.extension!,
        storyId,
        partId: partId && isPartHashId(partId) ? partId : undefined,
        chapterMeta,
        base,
      });
    }

    return base;
  }

  private getScrollProgressForProfile(): { percentage: number; scrollY: number } {
    const { document, window } = this.ctx;
    const contentRoot = getScrollRoot(document, this.profile.selectors);

    const scrollY = window.scrollY;
    const viewportBottom = scrollY + window.innerHeight;
    const contentTop = contentRoot.getBoundingClientRect().top + scrollY;
    const contentHeight = contentRoot.scrollHeight;
    const readableHeight = Math.max(contentHeight, 1);
    const readThrough = Math.max(0, viewportBottom - contentTop);
    const percentage = Math.min(100, Math.round((readThrough / readableHeight) * 100));

    return { percentage, scrollY };
  }
}

export function createProfileParser(ctx: ParserContext): ProfileParser | null {
  const profile = matchProfile(ctx.url, getBuiltinProfiles());
  if (!profile) return null;
  return new ProfileParser(ctx, profile);
}

export function createProfileParserForProfile(
  ctx: ParserContext,
  profile: SiteProfile,
): ProfileParser {
  return new ProfileParser(ctx, profile);
}

function normalizeStoryTitleCandidate(text?: string): string | undefined {
  if (!text) return undefined;
  const trimmed = text
    .replace(/^mời đọc tác phẩm:\s*/i, '')
    .replace(/^tác phẩm:\s*/i, '')
    .trim();
  if (!trimmed || isNavigationNoiseTitle(trimmed)) return undefined;
  return trimmed;
}
