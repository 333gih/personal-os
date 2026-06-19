import {
  collectMulubenAcronyms,
  countMulubenAcronyms,
  findMulubenEntry,
  getMulubenContainer,
  isInsideMuluben,
  isNavigationNoiseTitle,
  readHeaderChuongNumber,
  readVtqStoryTitle,
} from '../plugins/builtin/vietnamthuquan/muluben';
import type { ChapterClickHint } from '../content/chapter-hint';
import type {
  ChapterDetectionStrategy,
  DomChapterResult,
  DomStoryResult,
  SiteProfileSelectors,
} from '../types/site-profile';
import {
  extractQueryStoryId,
  extractUrlHashId,
  formatHashChapterTitle,
  isPartHashId,
} from './url-detector';

type CrawlContext = {
  document: Document;
  window: Window;
  url: string;
  chapterHint?: ChapterClickHint | null;
};

export function crawlStoryMeta(
  ctx: CrawlContext,
  selectors: SiteProfileSelectors,
  queryStoryParam?: string,
): DomStoryResult {
  const storyId = queryStoryParam ? extractQueryStoryId(ctx.url, queryStoryParam) : undefined;

  if (/vietnamthuquan|thuquansach/i.test(ctx.url)) {
    const vtqTitle = readVtqStoryTitle(ctx.document);
    if (vtqTitle) {
      return { storyId, storyTitle: vtqTitle, source: 'vtq_chuto40' };
    }
  }

  for (const selector of selectors.storyTitle ?? []) {
    for (const el of ctx.document.querySelectorAll(selector)) {
      const text = normalizeText(el.textContent);
      const normalized = text ? normalizeStoryTitle(text) : '';
      if (normalized) return { storyId, storyTitle: normalized, source: 'dom_story_title' };
    }
  }

  const ogTitle = getMeta(ctx.document, 'og:title');
  const normalizedOg = ogTitle ? normalizeStoryTitle(ogTitle) : '';
  if (normalizedOg) return { storyId, storyTitle: normalizedOg, source: 'og_title' };

  const titleParts = splitDocumentTitle(ctx.document.title);
  if (titleParts.storyTitle) {
    const normalizedDoc = normalizeStoryTitle(titleParts.storyTitle);
    if (normalizedDoc) {
      return {
        storyId,
        storyTitle: normalizedDoc,
        source: 'document_title',
      };
    }
  }

  const inviteMatch = normalizeText(ctx.document.body?.textContent?.slice(0, 500) ?? '').match(
    /mời đọc tác phẩm:\s*([^,\n]+)/i,
  );
  if (inviteMatch?.[1]) {
    return {
      storyId,
      storyTitle: normalizeStoryTitle(inviteMatch[1]),
      source: 'dom_invite_line',
    };
  }

  return storyId ? { storyId, source: 'url_query' } : {};
}

export function crawlChapterMeta(
  ctx: CrawlContext,
  selectors: SiteProfileSelectors,
  strategies: ChapterDetectionStrategy[],
  queryParams?: { story?: string; chapter?: string },
): DomChapterResult {
  for (const strategy of strategies) {
    const result = crawlByStrategy(ctx, selectors, strategy, queryParams);
    if (result.chapterId || result.chapterTitle) return result;
  }
  return {};
}

function crawlByStrategy(
  ctx: CrawlContext,
  selectors: SiteProfileSelectors,
  strategy: ChapterDetectionStrategy,
  queryParams?: { story?: string; chapter?: string },
): DomChapterResult {
  switch (strategy) {
    case 'url_query': {
      const chapterParam = queryParams?.chapter;
      if (!chapterParam) return {};
      const id = extractQueryStoryId(ctx.url, chapterParam);
      return id ? { chapterId: id, source: 'url_query' } : {};
    }
    case 'url_hash': {
      const hash = extractUrlHashId(ctx.url);
      if (!hash) return {};
      if (isPartHashId(hash)) {
        return {
          partId: hash,
          partTitle: formatHashChapterTitle(hash),
          source: 'url_hash_part_only',
        };
      }
      return {
        chapterId: hash,
        chapterTitle: formatHashChapterTitle(hash),
        source: 'url_hash',
      };
    }
    case 'url_path':
      return crawlChapterFromPath(ctx.url);
    case 'dom_toc':
      return crawlTableOfContents(ctx, selectors);
    case 'dom_chuongso':
      return crawlChapterFromChuongSo(ctx);
    case 'dom_select':
      return crawlChapterSelect(ctx);
    case 'dom_click_hint':
      return crawlFromClickHint(ctx);
    case 'dom_content_heading':
      return crawlContentChapterHeading(ctx, selectors);
    case 'dom_active':
      return crawlActiveChapter(ctx, selectors);
    case 'dom_visible':
      return crawlVisibleChapter(ctx, selectors);
    case 'title_split': {
      const parts = splitDocumentTitle(ctx.document.title);
      if (parts.chapterTitle) {
        return {
          chapterTitle: parts.chapterTitle,
          chapterId: slugify(parts.chapterTitle),
          source: 'document_title',
        };
      }
      return {};
    }
    default:
      return {};
  }
}

function crawlChapterFromPath(url: string): DomChapterResult {
  try {
    const parts = new URL(url).pathname.split('/').filter(Boolean);
    const chapterSegment = /^(?:chuong|chương|chapter|chap)-?(\d+(?:\.\d+)?)$/i;
    for (const part of parts) {
      const match = part.match(chapterSegment);
      if (match) {
        return {
          chapterId: match[1],
          chapterTitle: `Chương ${match[1]}`,
          source: 'url_path',
        };
      }
    }
  } catch {
    /* ignore */
  }
  return {};
}

function crawlTableOfContents(
  ctx: CrawlContext,
  selectors: SiteProfileSelectors,
): DomChapterResult {
  const hash = extractUrlHashId(ctx.url);
  const partId = hash && isPartHashId(hash) ? hash : undefined;
  const partTitle = partId ? formatHashChapterTitle(partId) : undefined;

  const entries = collectTocEntries(ctx.document, selectors.tableOfContents ?? []);
  if (entries.length === 0) {
    return partId ? { partId, partTitle, source: 'url_hash_part_only' } : {};
  }

  const active = findTocEntryByScroll(ctx, entries);
  if (!active) {
    return partId ? { partId, partTitle, source: 'url_hash_part_only' } : {};
  }

  const chapterUrl = buildDeepLinkUrl(ctx.url, active.anchorId);
  const chapterTitle = active.title;
  const chapterId = partId ? `${partId}:${active.anchorId}` : active.anchorId;

  return {
    chapterId,
    chapterTitle,
    chapterUrl,
    partId,
    partTitle,
    source: 'dom_toc',
  };
}

type TocEntry = {
  anchorId: string;
  title: string;
  top: number;
  chuongid?: string;
  tuaid?: string;
};

/** Scan entire page when mục lục container is not found (VTQ loads TOC at bottom). */
function collectTocEntriesFallback(document: Document, seen: Set<string>): TocEntry[] {
  const entries: TocEntry[] = [];

  for (const link of document.querySelectorAll('a[href*="#"]')) {
    const href = link.getAttribute('href') ?? '';
    const hash = href.includes('#') ? href.split('#').pop()?.trim() : '';
    if (!hash) continue;
    const title = normalizeText(link.textContent);
    if (!title || seen.has(hash) || isNavigationNoise(title)) continue;
    if (!looksLikeChapterLabel(title)) continue;

    const target = document.getElementById(hash);
    let top = target ? (target as HTMLElement).offsetTop : entries.length * 1000;
    seen.add(hash);
    entries.push({ anchorId: hash, title, top });
  }

  for (const el of document.querySelectorAll('[id]')) {
    const id = el.id.trim();
    if (!id || seen.has(id)) continue;
    const text = normalizeText(el.textContent?.slice(0, 200));
    if (!text || isNavigationNoise(text)) continue;
    const chapterMatch = text.match(/chương\s*(\d+)/i);
    if (!chapterMatch) continue;

    seen.add(id);
    entries.push({
      anchorId: id,
      title: text.slice(0, 120),
      top: (el as HTMLElement).offsetTop,
    });
  }

  return entries.sort((a, b) => a.top - b.top);
}

type ChapterCatalogEntry = {
  title: string;
  number?: string;
  anchorId?: string;
};

function extractChapterNumber(text: string): string | undefined {
  const match = text.match(/chương\s*(\d+)/i) ?? text.match(/^(\d+)[\s.:)/-]/);
  return match?.[1];
}

function formatChuongSoTitle(number: string, contextText?: string | null): string {
  const ctx = normalizeText(contextText);
  if (!ctx || isNoisyChapterText(ctx)) return `Chương ${number}`;
  if (ctx && /chương\s*\d+/i.test(ctx) && ctx.length <= 80) return ctx;
  if (ctx && ctx !== number && ctx.length > number.length && ctx.length <= 80) {
    const suffix = ctx.replace(new RegExp(`^${number}\\s*[-.:)]?\\s*`, 'i'), '').trim();
    return suffix ? `Chương ${number}: ${suffix}` : `Chương ${number}`;
  }
  return `Chương ${number}`;
}

export function isNoisyChapterText(text: string): boolean {
  const t = text.trim();
  if (t.length > 100) return true;
  if (/cỡ chữ/i.test(t)) return true;
  if (/^a\+|^a-$/i.test(t)) return true;
  if (/mục lục/i.test(t) && /chương\s*\d+/i.test(t)) return true;
  if ((t.match(/chương\s*\d+/gi) || []).length > 1) return true;
  return false;
}

export function readCurrentChuongNumber(document: Document): string | undefined {
  return readHeaderChuongNumber(document);
}

function readCurrentChuongSo(document: Document): { number: string; title: string } | null {
  const number = readHeaderChuongNumber(document);
  if (!number) return null;
  return { number, title: `Chương ${number}` };
}

function collectMulubenTocEntries(document: Document, seen: Set<string>): TocEntry[] {
  const acronymEntries = collectMulubenAcronyms(document);
  if (acronymEntries.length > 0) {
    return acronymEntries.map((entry) => {
      seen.add(entry.chuongid);
      return {
        anchorId: `chuong-${entry.chuongid}`,
        title: entry.title,
        top: entry.index * 1000,
        chuongid: entry.chuongid,
        tuaid: entry.tuaid,
      };
    });
  }

  const container = getMulubenContainer(document);
  if (!container) return [];

  const entries: TocEntry[] = [];

  for (const chuongEl of container.querySelectorAll('.chuongso, [class*="chuongso"]')) {
    const number = normalizeText(chuongEl.textContent);
    if (!number || !/^\d+$/.test(number) || seen.has(number)) continue;

    const row = chuongEl.closest('a, tr, li, td, div') ?? chuongEl.parentElement;
    const title = formatChuongSoTitle(number, row?.textContent);
    const link = chuongEl.closest('a') ?? row?.querySelector('a');
    const href = link?.getAttribute('href') ?? '';
    const anchorId = href.includes('#')
      ? href.split('#').pop()?.trim() || `chuong-${number}`
      : `chuong-${number}`;

    seen.add(number);
    entries.push({
      anchorId,
      title,
      top: entries.length * 1000,
    });
  }

  if (entries.length === 0) {
    for (const link of container.querySelectorAll('a')) {
      const title = normalizeText(link.textContent);
      if (!title || isNavigationNoise(title)) continue;
      const number = extractChapterNumber(title);
      const key = number ?? slugify(title);
      if (seen.has(key)) continue;

      const href = link.getAttribute('href') ?? '';
      const anchorId = href.includes('#')
        ? href.split('#').pop()?.trim() || key
        : key;

      seen.add(key);
      entries.push({
        anchorId,
        title,
        top: entries.length * 1000,
      });
    }
  }

  return entries;
}

export function countMulubenChapters(document: Document): number {
  const acronymCount = countMulubenAcronyms(document);
  if (acronymCount > 0) return acronymCount;
  const seen = new Set<string>();
  return collectMulubenTocEntries(document, seen).length;
}

function crawlChapterFromChuongSo(ctx: CrawlContext): DomChapterResult {
  const current = readCurrentChuongSo(ctx.document);
  if (!current) return {};

  const hash = extractUrlHashId(ctx.url);
  const partId = hash && isPartHashId(hash) ? hash : undefined;
  const partTitle = partId ? formatHashChapterTitle(partId) : undefined;
  const mulubenMatch = findMulubenEntry(ctx.document, current.number);

  return {
    chapterId: partId
      ? `${partId}:chuong-${mulubenMatch?.chuongid ?? current.number}`
      : `chuong-${mulubenMatch?.chuongid ?? current.number}`,
    chapterTitle: current.title,
    partId,
    partTitle,
    source: 'dom_chuongso',
    chapterIndex: mulubenMatch?.index,
    totalChapters: countMulubenChapters(ctx.document) || undefined,
  };
}

export function findChapterSelect(document: Document): HTMLSelectElement | null {
  let best: HTMLSelectElement | null = null;
  let bestScore = -1;

  for (const select of document.querySelectorAll('select')) {
    const options = Array.from(select.options).filter((o) => normalizeText(o.text));
    if (options.length < 2) continue;

    let score = options.length;
    const idName = `${select.id || ''} ${select.name || ''}`.toLowerCase();
    if (/chuong|chapter|ddl|lst/i.test(idName)) score += 50;
    if (score > bestScore) {
      bestScore = score;
      best = select;
    }
  }

  return best;
}

function crawlChapterSelect(ctx: CrawlContext): DomChapterResult {
  const select = findChapterSelect(ctx.document);
  if (!select || select.selectedIndex < 0) return {};

  const option = select.options[select.selectedIndex];
  const title = normalizeText(option.text);
  if (!title || isNavigationNoise(title)) return {};

  const hash = extractUrlHashId(ctx.url);
  const partId = hash && isPartHashId(hash) ? hash : undefined;
  const partTitle = partId ? formatHashChapterTitle(partId) : undefined;
  const chapterNum = extractChapterNumber(title);
  const chapterId = partId
    ? `${partId}:chuong-${chapterNum ?? slugify(title)}`
    : `chuong-${chapterNum ?? slugify(title)}`;

  return {
    chapterId,
    chapterTitle: title,
    partId,
    partTitle,
    source: 'dom_select',
  };
}

export function crawlChapterCatalog(
  ctx: CrawlContext,
  selectors: SiteProfileSelectors,
): ChapterCatalogEntry[] {
  const byKey = new Map<string, ChapterCatalogEntry>();

  const add = (title: string, anchorId?: string) => {
    if (!title || isNavigationNoise(title)) return;
    if (!looksLikeChapterLabel(title) && !extractChapterNumber(title)) return;
    const number = extractChapterNumber(title);
    const key = number ?? anchorId ?? slugify(title);
    if (byKey.has(key)) return;
    byKey.set(key, { title, number, anchorId });
  };

  const mulubenSeen = new Set<string>();
  for (const entry of collectMulubenTocEntries(ctx.document, mulubenSeen)) {
    add(entry.title, entry.anchorId);
  }

  const select = findChapterSelect(ctx.document);
  if (select) {
    for (const option of select.options) {
      add(normalizeText(option.text));
    }
  }

  for (const entry of collectTocEntries(ctx.document, selectors.tableOfContents ?? [])) {
    add(entry.title, entry.anchorId);
  }

  return Array.from(byKey.values()).sort((a, b) => {
    if (a.number && b.number) return Number(a.number) - Number(b.number);
    return 0;
  });
}

function crawlCurrentChapterTitle(
  ctx: CrawlContext,
  selectors: SiteProfileSelectors,
): string | undefined {
  const chuongSo = readCurrentChuongSo(ctx.document);
  if (chuongSo) return chuongSo.title;

  const select = findChapterSelect(ctx.document);
  if (select && select.selectedIndex >= 0) {
    const text = normalizeText(select.options[select.selectedIndex]?.text);
    if (text && !isNavigationNoise(text)) return text;
  }

  for (const sel of [
    ...(selectors.chapterTitle ?? []),
    '.chuongso',
    '#TenChuong',
    '.ten-chuong',
    '.chapter-title',
    '.chapter-heading',
  ]) {
    const text = getText(ctx.document, sel);
    if (text && !isNavigationNoise(text)) return text;
  }

  for (const root of getContentRoots(ctx.document, selectors)) {
    for (const heading of root.querySelectorAll('h1, h2, h3')) {
      if (isInsideNavigation(heading)) continue;
      const text = normalizeText(heading.textContent);
      if (text && /chương\s*\d+/i.test(text) && !isNavigationNoise(text)) return text;
    }
  }

  const titleParts = splitDocumentTitle(ctx.document.title);
  if (titleParts.chapterTitle && /chương\s*\d+/i.test(titleParts.chapterTitle)) {
    return titleParts.chapterTitle;
  }

  return undefined;
}

/** VTQ manual sync: full mục lục count + current chapter from select/title. */
export function crawlVtqSyncMeta(
  ctx: CrawlContext,
  selectors: SiteProfileSelectors,
): DomChapterResult {
  const catalog = crawlChapterCatalog(ctx, selectors);
  const totalChapters = catalog.length;
  const currentTitle = crawlCurrentChapterTitle(ctx, selectors);

  const hash = extractUrlHashId(ctx.url);
  const partId = hash && isPartHashId(hash) ? hash : undefined;
  const partTitle = partId ? formatHashChapterTitle(partId) : undefined;

  if (!currentTitle) {
    return {
      partId,
      partTitle,
      totalChapters,
      source: 'vtq_sync_catalog_only',
    };
  }

  const currentNum = extractChapterNumber(currentTitle);
  let chapterIndex = currentNum
    ? catalog.findIndex((entry) => entry.number === currentNum) + 1
    : catalog.findIndex((entry) => entry.title === currentTitle) + 1;

  if (chapterIndex <= 0 && currentNum) {
    chapterIndex = Number(currentNum);
  }

  const chapterId = partId
    ? `${partId}:chuong-${currentNum ?? chapterIndex}`
    : `chuong-${currentNum ?? chapterIndex}`;

  return {
    chapterId,
    chapterTitle: currentTitle,
    partId,
    partTitle,
    totalChapters,
    chapterIndex: chapterIndex > 0 ? chapterIndex : undefined,
    source: 'vtq_sync',
  };
}

function crawlFromClickHint(ctx: CrawlContext): DomChapterResult {
  const hint = ctx.chapterHint;
  if (!hint) return {};

  const hash = extractUrlHashId(ctx.url);
  const partId = hash && isPartHashId(hash) ? hash : undefined;
  const partTitle = partId ? formatHashChapterTitle(partId) : undefined;

  const anchorId =
    hint.anchorId ??
    resolveAnchorForChapter(ctx, hint.chapterNumber) ??
    `chuong-${hint.chapterNumber}`;

  const chapterId = partId
    ? `${partId}:chuong-${hint.chapterNumber}`
    : `chuong-${hint.chapterNumber}`;

  return {
    chapterId,
    chapterTitle: hint.chapterTitle,
    chapterUrl: buildDeepLinkUrl(ctx.url, anchorId),
    partId,
    partTitle,
    source: 'dom_click_hint',
  };
}

function resolveAnchorForChapter(ctx: CrawlContext, chapterNumber: string): string | undefined {
  const candidates = [
    `chuong-${chapterNumber}`,
    `Chuong${chapterNumber}`,
    `c${chapterNumber}`,
    `C${chapterNumber}`,
  ];

  for (const id of candidates) {
    if (ctx.document.getElementById(id)) return id;
  }

  const chapterPattern = new RegExp(`chương\\s*${chapterNumber}\\b`, 'i');
  for (const root of getContentRoots(ctx.document, {})) {
    for (const el of root.querySelectorAll('[id]')) {
      const text = normalizeText(el.textContent?.slice(0, 200));
      if (text && chapterPattern.test(text)) return el.id;
    }
  }

  return undefined;
}

function crawlContentChapterHeading(
  ctx: CrawlContext,
  selectors: SiteProfileSelectors,
): DomChapterResult {
  const hash = extractUrlHashId(ctx.url);
  const partId = hash && isPartHashId(hash) ? hash : undefined;
  const partTitle = partId ? formatHashChapterTitle(partId) : undefined;
  const probe = ctx.window.scrollY + ctx.window.innerHeight * 0.28;
  const chapterPattern = /chương\s*(\d+)/i;

  const roots = getContentRoots(ctx.document, selectors);
  let best: { top: number; num: string; title: string; anchorId: string } | null = null;

  for (const root of roots) {
    for (const el of root.querySelectorAll('h1,h2,h3,h4,h5,h6,strong,b,p,div,span')) {
      if (isInsideNavigation(el)) continue;
      const text = normalizeText(el.textContent);
      if (!text || isNavigationNoise(text)) continue;

      const match = text.match(chapterPattern);
      if (!match) continue;

      const top = el.getBoundingClientRect().top + ctx.window.scrollY;
      if (top > probe + 120) continue;
      if (!best || top > best.top || (top === best.top && Number(match[1]) > Number(best.num))) {
        const anchorId = findNearestAnchorId(el) ?? `chuong-${match[1]}`;
        best = {
          top,
          num: match[1],
          title: text.slice(0, 160),
          anchorId,
        };
      }
    }
  }

  if (!best) return {};

  const chapterId = partId ? `${partId}:chuong-${best.num}` : `chuong-${best.num}`;
  return {
    chapterId,
    chapterTitle: best.title,
    chapterUrl: buildDeepLinkUrl(ctx.url, best.anchorId),
    partId,
    partTitle,
    source: 'dom_content_heading',
  };
}

function getContentRoots(document: Document, selectors: SiteProfileSelectors): Element[] {
  const roots: Element[] = [];
  const seen = new Set<Element>();
  const add = (el: Element | null) => {
    if (el && !seen.has(el)) {
      seen.add(el);
      roots.push(el);
    }
  };

  for (const sel of [
    ...(selectors.contentRoot ?? []),
    '#noidungchuang',
    '#noidungdung',
    '#noidung',
    '.noidung',
    '#content',
    'article',
    'main',
    'body',
  ]) {
    document.querySelectorAll(sel).forEach((el) => add(el));
  }
  return roots.length > 0 ? roots : [document.body];
}

function findNearestAnchorId(el: Element): string | undefined {
  if (el.id) return el.id;
  const closest = el.closest('[id]');
  if (closest?.id && !isNavigationNoise(closest.id)) return closest.id;
  return undefined;
}

function isInsideNavigation(el: Element): boolean {
  return Boolean(
    el.closest(
      'nav,.nav,.navigation,.pagination,.pager,[class*="pager"],[class*="dieuhuong"],[class*="nav-chapter"],[id*="DieuHuong"],[id*="dieu-huong"]',
    ),
  );
}

function isNavigationNoise(text: string): boolean {
  const t = text.trim();
  if (t.length < 3) return true;
  if (isNoisyChapterText(t)) return true;
  if (/^<<.*>>$/i.test(t)) return true;
  if (/lui/i.test(t) && /(tiến|tien|☆|-)/i.test(t)) return true;
  if (/^(lui|tiến|tien|prev|next|trước|sau|back|forward)$/i.test(t)) return true;
  if (/^(mục lục|danh sách chương)$/i.test(t)) return true;
  if (/^a\+$|^a-$/i.test(t)) return true;
  return false;
}

function collectTocEntriesFromContainers(
  document: Document,
  containers: Element[],
  seen: Set<string>,
): TocEntry[] {
  const entries: TocEntry[] = [];

  for (const container of containers) {
    for (const link of container.querySelectorAll('a[href^="#"], a[href*="#"]')) {
      const href = link.getAttribute('href') ?? '';
      const anchorId = (href.includes('#') ? href.split('#').pop() : href.replace(/^#/, ''))?.trim();
      const title = normalizeText(link.textContent);
      if (!anchorId || !title || seen.has(anchorId)) continue;
      if (isNavigationNoise(title) || !looksLikeChapterLabel(title)) continue;

      const target = document.getElementById(anchorId);
      let top = 0;
      if (target) {
        const rectTop = target.getBoundingClientRect().top + (document.defaultView?.scrollY ?? 0);
        top = rectTop > 0 ? rectTop : (target as HTMLElement).offsetTop;
      } else {
        top = entries.length * 1000;
      }

      seen.add(anchorId);
      entries.push({ anchorId, title, top });
    }
  }

  return entries;
}

function collectTocEntries(document: Document, tocSelectors: string[]): TocEntry[] {
  const seen = new Set<string>();
  let entries = collectMulubenTocEntries(document, seen);

  if (entries.length === 0) {
    const containers = findTocContainers(document, tocSelectors);
    entries = collectTocEntriesFromContainers(document, containers, seen);
  }

  if (entries.length === 0) {
    entries = collectTocEntriesFallback(document, seen);
  }

  return entries.sort((a, b) => a.top - b.top);
}

function findTocContainers(document: Document, tocSelectors: string[]): Element[] {
  const found: Element[] = [];
  const seen = new Set<Element>();

  const add = (el: Element | null | undefined) => {
    if (el && !seen.has(el)) {
      seen.add(el);
      found.push(el);
    }
  };

  const defaultSelectors = [
    '#muluben_to',
    '[id*="muluben"]',
    '#mucluc',
    '.mucluc',
    '.muc-luc',
    '#muc-luc',
    '[id*="mucluc"]',
    '[class*="mucluc"]',
    '#danhsachchuong',
    '.danh-sach-chuong',
  ];

  for (const sel of [...tocSelectors, ...defaultSelectors]) {
    document.querySelectorAll(sel).forEach((el) => add(el));
  }

  for (const heading of document.querySelectorAll('h2, h3, h4, strong, b, span, div')) {
    const text = normalizeText(heading.textContent);
    if (!/^mục lục$/i.test(text) && !/danh sách chương/i.test(text)) continue;
    add(heading.parentElement);
    add(heading.nextElementSibling);
    const list = heading.parentElement?.querySelector('ul, ol, table, div');
    add(list ?? null);
  }

  return found;
}

function findTocEntryByScroll(ctx: CrawlContext, entries: TocEntry[]): TocEntry | null {
  if (entries.length === 0) return null;

  const distinctTops = new Set(entries.map((e) => e.top));
  if (distinctTops.size === 1) {
    const scrollHeight = Math.max(
      ctx.document.body?.scrollHeight ?? 0,
      ctx.document.documentElement.scrollHeight,
      1,
    );
    const ratio = ctx.window.scrollY / scrollHeight;
    const index = Math.min(entries.length - 1, Math.floor(ratio * entries.length));
    return entries[index];
  }

  const probe = ctx.window.scrollY + ctx.window.innerHeight * 0.3;
  let active: TocEntry = entries[0];

  for (const entry of entries) {
    if (entry.top <= probe + 80) active = entry;
    else break;
  }

  return active;
}

function buildDeepLinkUrl(pageUrl: string, anchorId: string): string {
  try {
    const url = new URL(pageUrl);
    url.hash = anchorId;
    return url.href;
  } catch {
    const base = pageUrl.split('#')[0];
    return `${base}#${anchorId}`;
  }
}

function looksLikeChapterLabel(text: string): boolean {
  return (
    /chương\s*\d+/i.test(text) ||
    /chapter\s*\d+/i.test(text) ||
    /^\d+[\s.:)/-]/i.test(text) ||
    /hồi\s*\d+/i.test(text) ||
    /phần\s*\d+/i.test(text)
  );
}

function normalizeStoryTitle(text: string): string {
  const cleaned = text
    .replace(/^mời đọc tác phẩm:\s*/i, '')
    .replace(/^tác phẩm:\s*/i, '')
    .trim();
  if (isNavigationNoiseTitle(cleaned)) return '';
  return cleaned;
}

export function getChapterBoundedProgress(
  ctx: CrawlContext,
  selectors: SiteProfileSelectors,
  chapterMeta: DomChapterResult,
): { percentage: number; scrollY: number } | null {
  if (chapterMeta.source !== 'dom_toc' &&
    chapterMeta.source !== 'dom_content_heading' &&
    chapterMeta.source !== 'dom_click_hint' &&
    chapterMeta.source !== 'dom_chuongso' &&
    chapterMeta.source !== 'vtq_sync'
  ) {
    return null;
  }

  const entries = collectTocEntries(ctx.document, selectors.tableOfContents ?? []);
  if (entries.length === 0 && chapterMeta.source !== 'vtq_sync') return null;

  if (chapterMeta.source === 'vtq_sync' && chapterMeta.chapterIndex && chapterMeta.totalChapters) {
    const percentage = Math.min(
      100,
      Math.max(0, Math.round((chapterMeta.chapterIndex / chapterMeta.totalChapters) * 100)),
    );
    return { percentage, scrollY: ctx.window.scrollY };
  }

  const anchorId = chapterMeta.chapterId.includes(':')
    ? chapterMeta.chapterId.split(':').pop()!
    : chapterMeta.chapterId;

  const index = entries.findIndex((e) => e.anchorId === anchorId);
  if (index < 0) return null;

  const start = entries[index].top;
  const end =
    entries[index + 1]?.top ??
    getScrollRoot(ctx.document, selectors).getBoundingClientRect().top +
      ctx.window.scrollY +
      getScrollRoot(ctx.document, selectors).scrollHeight;

  const probe = ctx.window.scrollY + ctx.window.innerHeight * 0.5;
  const span = Math.max(end - start, 1);
  const percentage = Math.min(100, Math.max(0, Math.round(((probe - start) / span) * 100)));

  return { percentage, scrollY: ctx.window.scrollY };
}

function crawlActiveChapter(
  ctx: CrawlContext,
  selectors: SiteProfileSelectors,
): DomChapterResult {
  const listSelectors = [
    ...(selectors.chapterList ?? []),
    '.list-chapter',
    '#list-chapter',
    '.chapter-list',
    '[class*="chuong"]',
    '.sidebar',
    'aside',
  ];

  const itemSelectors = selectors.chapterListItem ?? ['a', 'li', 'option'];
  const activeSelectors = selectors.chapterActive ?? [
    '.active',
    '.current',
    '.selected',
    '[aria-current="page"]',
    '.chuong-dang-doc',
    '.dang-doc',
  ];

  for (const listSel of listSelectors) {
    const lists = ctx.document.querySelectorAll(listSel);
    for (const list of lists) {
      const active = findActiveInContainer(list, itemSelectors, activeSelectors);
      if (active) return { ...active, source: 'dom_active' };
    }
  }

  for (const sel of selectors.chapterTitle ?? []) {
    const text = getText(ctx.document, sel);
    if (text) {
      return { chapterTitle: text, chapterId: slugify(text), source: 'dom_chapter_title' };
    }
  }

  return crawlActiveFromNav(ctx.document);
}

function findActiveInContainer(
  container: Element,
  itemSelectors: string[],
  activeSelectors: string[],
): DomChapterResult | null {
  for (const activeSel of activeSelectors) {
    const activeEl = container.querySelector(activeSel);
    if (activeEl) {
      const link = activeEl.closest('a') ?? activeEl.querySelector('a');
      const text = normalizeText(activeEl.textContent ?? link?.textContent);
      const href = link?.getAttribute('href') ?? activeEl.getAttribute('href');
      if (text && !isNavigationNoise(text)) {
        return {
          chapterTitle: text,
          chapterId: chapterIdFromHref(href) ?? slugify(text),
        };
      }
    }
  }

  for (const itemSel of itemSelectors) {
    const items = container.querySelectorAll(itemSel);
    for (const item of items) {
      if (!looksActive(item)) continue;
      const link = item.tagName === 'A' ? item : item.querySelector('a');
      const text = normalizeText(item.textContent);
      const href = link?.getAttribute('href') ?? item.getAttribute('href');
      if (text && !isNavigationNoise(text)) {
        return {
          chapterTitle: text,
          chapterId: chapterIdFromHref(href) ?? slugify(text),
        };
      }
    }
  }

  return null;
}

function crawlActiveFromNav(document: Document): DomChapterResult {
  const navSelectors = [
    '.chapter-nav .active',
    '.nav-chapter .active',
    '.pagination .active',
    '.page-item.active',
    'select option[selected]',
  ];
  for (const sel of navSelectors) {
    const el = document.querySelector(sel);
    const text = normalizeText(el?.textContent);
    if (text && !isNavigationNoise(text)) {
      return { chapterTitle: text, chapterId: slugify(text), source: 'dom_nav_active' };
    }
  }
  return {};
}

function crawlVisibleChapter(
  ctx: CrawlContext,
  selectors: SiteProfileSelectors,
): DomChapterResult {
  const roots = selectors.contentRoot ?? [
    '#chapter-content',
    '.chapter-c',
    '.reading-content',
    'article',
    'main',
  ];

  const viewportMid = ctx.window.scrollY + ctx.window.innerHeight * 0.35;

  for (const rootSel of roots) {
    const root = ctx.document.querySelector(rootSel);
    if (!root) continue;

    const headings = root.querySelectorAll('h1, h2, h3, h4, .chapter-title, [class*="chuong"]');
    let best: { el: Element; dist: number } | null = null;

    for (const heading of headings) {
      const text = normalizeText(heading.textContent);
      if (!text || text.length < 2 || isNavigationNoise(text)) continue;
      const top = heading.getBoundingClientRect().top + ctx.window.scrollY;
      const dist = Math.abs(top - viewportMid);
      if (!best || dist < best.dist) best = { el: heading, dist };
    }

    if (best) {
      const text = normalizeText(best.el.textContent);
      if (isNoisyChapterText(text)) return {};
      return {
        chapterTitle: text,
        chapterId: slugify(text),
        source: 'dom_visible',
      };
    }
  }

  return {};
}

export function getScrollRoot(document: Document, selectors: SiteProfileSelectors): HTMLElement {
  for (const sel of selectors.contentRoot ?? []) {
    const el = document.querySelector<HTMLElement>(sel);
    if (el) return el;
  }
  return document.documentElement;
}

export function findChapterListRoots(
  document: Document,
  selectors: SiteProfileSelectors,
): Element[] {
  const roots: Element[] = [];
  const seen = new Set<Element>();
  const listSelectors = [
    ...(selectors.chapterList ?? []),
    '#muluben_to',
    '[id*="muluben"]',
    '.list-chapter',
    '#list-chapter',
    '.chapter-list',
    '[class*="chuong"]',
    'aside',
    '.sidebar',
  ];

  for (const sel of listSelectors) {
    for (const el of document.querySelectorAll(sel)) {
      if (!seen.has(el)) {
        seen.add(el);
        roots.push(el);
      }
    }
  }
  return roots;
}

function looksActive(el: Element): boolean {
  const cls = el.className?.toString().toLowerCase() ?? '';
  if (/(active|current|selected|dang-doc|highlight)/i.test(cls)) return true;
  if (el.getAttribute('aria-current') === 'page') return true;
  if (el.querySelector('b, strong')) return true;
  const fontWeight = getComputedStyle(el).fontWeight;
  return fontWeight === 'bold' || Number(fontWeight) >= 600;
}

function chapterIdFromHref(href: string | null | undefined): string | undefined {
  if (!href) return undefined;
  const hash = href.includes('#') ? href.split('#')[1] : undefined;
  if (hash) return hash;
  const slug = href.split('/').filter(Boolean).pop();
  return slug ? slugify(slug) : undefined;
}

function splitDocumentTitle(title: string): {
  storyTitle?: string;
  chapterTitle?: string;
} {
  const separators = [' - ', ' | ', ' — ', ' » ', ' > ', ' – '];
  for (const sep of separators) {
    if (!title.includes(sep)) continue;
    const parts = title.split(sep).map((p) => p.trim()).filter(Boolean);
    if (parts.length >= 2) {
      return { chapterTitle: parts[0], storyTitle: parts[parts.length - 1] };
    }
  }
  return { storyTitle: title.trim() || undefined };
}

function getText(document: Document, selector: string): string | undefined {
  const el = document.querySelector(selector);
  const text = normalizeText(el?.textContent);
  return text || undefined;
}

function getMeta(document: Document, property: string): string | undefined {
  const el = document.querySelector(`meta[property="${property}"], meta[name="${property}"]`);
  return el?.getAttribute('content')?.trim() || undefined;
}

function normalizeText(value: string | null | undefined): string {
  return (value ?? '').replace(/\s+/g, ' ').trim();
}

function slugify(value: string): string {
  return value
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 120);
}
