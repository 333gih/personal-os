import type { SitePlugin, SitePluginInput } from '../../types';
import { getCatalogTotal, setCatalogTotal } from '../../../storage/catalog-cache';
import { countMulubenChapters, readCurrentChuongNumber } from '../../../parsers/dom-crawler';
import { extractUrlHashId, formatHashChapterTitle, isPartHashId } from '../../../parsers/url-detector';
import type { DomChapterResult } from '../../../types/site-profile';
import {
  buildNoidungArgFromIds,
  collectMulubenAcronyms,
  findMulubenEntry,
  readHeaderChuongNumber,
  readTuaidFromCatalog,
  readTuaidFromUrl,
  readVtqStoryTitle,
  isNavigationNoiseTitle,
  triggerMulubenChapter,
} from './muluben';

function chapterNumberFromMeta(meta: DomChapterResult, hint?: string | null): string | undefined {
  if (hint) return hint;
  const fromId = meta.chapterId?.match(/chuong-(\d+)/i)?.[1];
  if (fromId) return fromId;
  const fromTitle = meta.chapterTitle?.match(/chương\s*(\d+)/i)?.[1];
  return fromTitle;
}

export const vietnamThuQuanPlugin: SitePlugin = {
  id: 'vietnamthuquan',
  label: 'Vietnam Thu Quan',
  description:
    'Postback reader: .chuongso header + #muluben_to acronym catalog + noidung1() resume.',
  builtin: true,

  async enhance({ ctx, extension, storyId, partId, chapterMeta, base }) {
    const chapterNumber =
      readHeaderChuongNumber(ctx.document) ??
      chapterNumberFromMeta(chapterMeta, ctx.chapterHint?.chapterNumber) ??
      readCurrentChuongNumber(ctx.document);

    const mulubenMatch = chapterNumber
      ? findMulubenEntry(ctx.document, chapterNumber, ctx.chapterHint?.chuongid)
      : undefined;

    const cacheKey = `${storyId}:${partId ?? 'default'}`;
    let totalChapters: number | undefined;

    if (extension.cacheCatalog !== false) {
      const cached = await getCatalogTotal('vietnamthuquan', cacheKey);
      if (cached) totalChapters = cached;
    }

    const liveCount = countMulubenChapters(ctx.document);
    const shouldScan =
      ctx.syncMode || !totalChapters || (liveCount > 0 && liveCount > (totalChapters ?? 0));

    if (shouldScan && liveCount > 0) {
      totalChapters = liveCount;
      if (extension.cacheCatalog !== false) {
        await setCatalogTotal('vietnamthuquan', cacheKey, liveCount);
      }
    } else if (!totalChapters && chapterMeta.totalChapters) {
      totalChapters = chapterMeta.totalChapters;
    }

    const chapterIndex =
      mulubenMatch?.index ?? (chapterNumber ? Number(chapterNumber) : chapterMeta.chapterIndex);
    const partTitle = partId && isPartHashId(partId) ? formatHashChapterTitle(partId) : undefined;

    let chapterTitle = chapterNumber ? `Chương ${chapterNumber}` : undefined;
    if (chapterNumber && totalChapters) {
      chapterTitle = `Chương ${chapterNumber} / ${totalChapters}`;
    }

    const percentage =
      chapterIndex && totalChapters
        ? Math.min(100, Math.max(0, Math.round((chapterIndex / totalChapters) * 100)))
        : base.progress.percentage;

    const acronyms = collectMulubenAcronyms(ctx.document);

    const storyTitleSelector = extension.fields?.storyTitle ?? 'span.chuto40, .chuto40';
    const vtqStoryTitle = readVtqStoryTitle(ctx.document, storyTitleSelector);
    const fallbackTitle =
      base.storyTitle && !isNavigationNoiseTitle(base.storyTitle) ? base.storyTitle : undefined;
    const storyTitle = vtqStoryTitle ?? fallbackTitle ?? 'Unknown story';

    const resolvedChuongid =
      mulubenMatch?.chuongid ?? ctx.chapterHint?.chuongid ?? ctx.chapterHint?.chapterNumber;
    const resolvedTuaid =
      mulubenMatch?.tuaid ??
      ctx.chapterHint?.tuaid ??
      readTuaidFromUrl(ctx.url) ??
      readTuaidFromCatalog(ctx.document);
    const noidungArg =
      mulubenMatch?.onclickArg ??
      (typeof ctx.chapterHint?.noidungArg === 'string' ? ctx.chapterHint.noidungArg : undefined) ??
      (resolvedTuaid && resolvedChuongid
        ? buildNoidungArgFromIds(resolvedTuaid, resolvedChuongid)
        : undefined);

    return {
      ...base,
      storyTitle,
      chapterTitle,
      chapterId: partId
        ? `${partId}:chuong-${mulubenMatch?.chuongid ?? chapterNumber ?? 'unknown'}`
        : `chuong-${mulubenMatch?.chuongid ?? chapterNumber ?? 'unknown'}`,
      progress: {
        ...base.progress,
        percentage,
      },
      metadata: {
        ...base.metadata,
        display_format: extension.displayFormat ?? 'chapter_of_total',
        chapter_number: chapterNumber ?? mulubenMatch?.displayNumber,
        chapter_index: chapterIndex,
        total_chapters: totalChapters,
        chuongid: resolvedChuongid,
        tuaid: resolvedTuaid,
        noidung_arg: noidungArg,
        catalog_count: acronyms.length,
        part_title: partTitle,
        part_id: partId ?? extractUrlHashId(ctx.url),
        catalog_cached: Boolean(totalChapters && !shouldScan),
        story_source: vtqStoryTitle ? 'vtq_chuto40' : base.metadata?.story_source,
        site_handler: 'vietnamthuquan',
        site_plugin: 'vietnamthuquan',
        support_contact: extension.supportContact,
      },
    };
  },

  async resumeChapter(document, payload) {
    const chuongid = payload.chuongid ?? payload.chapterNumber;
    const pageUrl = document.defaultView?.location?.href;
    const tuaid =
      payload.tuaid ??
      (pageUrl ? readTuaidFromUrl(pageUrl) : undefined) ??
      readTuaidFromCatalog(document);
    return triggerMulubenChapter(
      document,
      payload.chapterNumber,
      chuongid,
      tuaid,
      payload.noidungArg,
    );
  },
};
