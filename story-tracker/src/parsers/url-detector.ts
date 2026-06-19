/** Heuristic URL signals for Vietnamese / novel reading sites. */

const READING_PATH_KEYWORDS = [
  'truyen',
  'chuong',
  'chapter',
  'thu-vien',
  'thuvien',
  'thu-quan',
  'doc-truyen',
  'nettruyen',
  'truyenqq',
  'read',
  'novel',
  'fiction',
] as const;

const READING_HOST_KEYWORDS = [
  'truyen',
  'thuquan',
  'thuvien',
  'novel',
  'fiction',
  'doc-truyen',
  'nettruyen',
] as const;

const LISTING_PATH_PATTERNS = [
  /^\/$/,
  /^\/danh-sach(?:\/|$)/i,
  /^\/the-loai(?:\/|$)/i,
  /^\/category(?:\/|$)/i,
  /^\/search(?:\/|$)/i,
  /^\/login(?:\/|$)/i,
  /^\/account(?:\/|$)/i,
];

export function hasReadingPathKeywords(url: string): boolean {
  try {
    const parsed = new URL(url);
    const blob = `${parsed.pathname}${parsed.search}`.toLowerCase();
    return READING_PATH_KEYWORDS.some((kw) => blob.includes(kw));
  } catch {
    return false;
  }
}

export function hasReadingHostKeywords(url: string): boolean {
  try {
    const hostname = new URL(url).hostname.toLowerCase();
    return READING_HOST_KEYWORDS.some((kw) => hostname.includes(kw));
  } catch {
    return false;
  }
}

export function isLikelyListingPage(url: string): boolean {
  try {
    const pathname = new URL(url).pathname;
    return LISTING_PATH_PATTERNS.some((rule) => rule.test(pathname));
  } catch {
    return false;
  }
}

export function hasReadingUrlSignals(url: string): boolean {
  if (isLikelyListingPage(url)) return false;
  if (hasReadingPathKeywords(url)) return true;

  try {
    const parsed = new URL(url);
    const parts = parsed.pathname.split('/').filter(Boolean);
    // Host-only match (e.g. truyenfull.today) needs a deeper path — not story index.
    if (parts.length <= 1) return false;
    return hasReadingHostKeywords(url);
  } catch {
    return false;
  }
}

export function extractQueryStoryId(
  url: string,
  paramName = 'tid',
): string | undefined {
  try {
    return new URL(url).searchParams.get(paramName)?.trim() || undefined;
  } catch {
    return undefined;
  }
}

export function extractUrlHashId(url: string): string | undefined {
  try {
    const hash = new URL(url).hash.replace(/^#/, '').trim();
    return hash || undefined;
  } catch {
    return undefined;
  }
}

export function formatHashChapterTitle(hash: string): string {
  if (/^phandau$/i.test(hash)) return 'Phần đầu';
  const phanMatch = hash.match(/^phan(\d+)$/i);
  if (phanMatch) return `Phần ${phanMatch[1]}`;
  const chuongMatch = hash.match(/^chuong[-_]?(\d+)/i);
  if (chuongMatch) return `Chương ${chuongMatch[1]}`;
  const cMatch = hash.match(/^c(\d+)$/i);
  if (cMatch) return `Chương ${cMatch[1]}`;
  return hash;
}

/** VTQ-style part anchors (#phandau, #phan2) — not a specific chapter. */
export function isPartHashId(hash: string): boolean {
  return /^phandau$/i.test(hash) || /^phan\d+$/i.test(hash);
}
