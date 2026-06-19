export type VtqMulubenEntry = {
  index: number;
  chuongid: string;
  tuaid?: string;
  displayNumber: string;
  title: string;
  onclickArg?: string;
};

export type VtqNoidungParams = {
  tuaid?: string;
  chuongid?: string;
  raw?: string;
};

export function getMulubenContainer(document: Document): Element | null {
  return document.querySelector('#muluben_to, [id*="muluben_to"], [id*="muluben"]');
}

export function parseNoidungOnclick(onclick: string | null | undefined): VtqNoidungParams {
  if (!onclick) return {};
  const match = onclick.match(/noidung1\s*\(\s*['"]([^'"]+)['"]/i);
  if (!match?.[1]) return {};
  const raw = match[1];
  return {
    raw,
    tuaid: raw.match(/tuaid=(\d+)/i)?.[1],
    chuongid: raw.match(/chuongid=(\d+)/i)?.[1],
  };
}

export function parseNoidungFromElement(el: Element): VtqNoidungParams {
  const onclick =
    el.getAttribute('onclick') ??
    el.querySelector('[onclick*="noidung"]')?.getAttribute('onclick') ??
    undefined;
  return parseNoidungOnclick(onclick);
}

export function extractDigits(value: string | null | undefined): string | undefined {
  const text = (value ?? '').replace(/\s+/g, ' ').trim();
  if (!text) return undefined;
  if (/^\d+$/.test(text)) return text;
  const match = text.match(/(\d+)/);
  return match?.[1];
}

export function isInsideMuluben(el: Element): boolean {
  return Boolean(el.closest('#muluben_to, [id*="muluben"]'));
}

export function collectMulubenAcronyms(document: Document): VtqMulubenEntry[] {
  const container = getMulubenContainer(document);
  if (!container) return [];

  const entries: VtqMulubenEntry[] = [];
  let index = 0;

  for (const acronym of container.querySelectorAll('acronym')) {
    const params = parseNoidungFromElement(acronym);
    const displayNumber =
      extractDigits(acronym.querySelector('.chuongso, [class*="chuongso"]')?.textContent) ??
      params.chuongid;

    if (!displayNumber && !params.chuongid) continue;

    const chuongid = params.chuongid ?? displayNumber!;
    const title = `Chương ${displayNumber ?? chuongid}`;

    index += 1;
    entries.push({
      index,
      chuongid,
      tuaid: params.tuaid,
      displayNumber: displayNumber ?? chuongid,
      title,
      onclickArg: params.raw,
    });
  }

  return entries;
}

export function countMulubenAcronyms(document: Document): number {
  const container = getMulubenContainer(document);
  if (!container) return 0;
  return container.querySelectorAll('acronym').length;
}

export function readHeaderChuongNumber(document: Document): string | undefined {
  const headerSelectors = [
    '#tieude .chuongso',
    '#tieudechuong .chuongso',
    '#dautrang .chuongso',
    '#TenChuong',
    '.chuongso',
    '[class*="chuongso"]',
  ];

  for (const sel of headerSelectors) {
    for (const el of document.querySelectorAll(sel)) {
      if (isInsideMuluben(el)) continue;
      const number = extractDigits(el.textContent);
      if (number) return number;
    }
  }

  return undefined;
}

export function findMulubenEntry(
  document: Document,
  chapterNumber: string,
  chuongid?: string,
): VtqMulubenEntry | undefined {
  const entries = collectMulubenAcronyms(document);
  return entries.find(
    (entry) =>
      entry.chuongid === chuongid ||
      entry.chuongid === chapterNumber ||
      entry.displayNumber === chapterNumber,
  );
}

export function buildNoidungArg(entry: VtqMulubenEntry): string | undefined {
  if (entry.onclickArg) return entry.onclickArg;
  if (entry.tuaid && entry.chuongid) return `tuaid=${entry.tuaid}&chuongid=${entry.chuongid}`;
  if (entry.chuongid) return `chuongid=${entry.chuongid}`;
  return undefined;
}

export function triggerMulubenChapter(
  document: Document,
  chapterNumber: string,
  chuongid?: string,
): boolean {
  const container = getMulubenContainer(document);
  if (!container) return false;

  if (typeof container.scrollIntoView === 'function') {
    container.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
  }

  const entry = findMulubenEntry(document, chapterNumber, chuongid);
  if (!entry) return false;

  for (const acronym of container.querySelectorAll('acronym')) {
    const params = parseNoidungFromElement(acronym);
    const displayNumber = extractDigits(
      acronym.querySelector('.chuongso, [class*="chuongso"]')?.textContent,
    );
    const cid = params.chuongid ?? displayNumber;
    if (cid !== entry.chuongid && displayNumber !== entry.displayNumber) continue;

    const win = (document.defaultView ?? globalThis.window) as
      | (Window & { noidung1?: (arg: string) => void })
      | null;
    const arg = buildNoidungArg(entry) ?? params.raw;
    if (arg && typeof win?.noidung1 === 'function') {
      win.noidung1(arg);
      return true;
    }

    const clickTarget =
      acronym.querySelector('[onclick*="noidung"]') ??
      acronym.querySelector('div') ??
      acronym;
    if (clickTarget instanceof HTMLElement) {
      clickTarget.click();
      return true;
    }
  }

  return false;
}

/** VTQ reader nav buttons — not a story title. */
export function isNavigationNoiseTitle(text: string): boolean {
  const trimmed = text.replace(/\s+/g, ' ').trim();
  if (!trimmed) return true;
  if (/^<<.*>>$/i.test(trimmed)) return true;
  if (/^«.*»$/i.test(trimmed)) return true;
  if (/\blui\b/i.test(trimmed) && /\btiến\b/i.test(trimmed) && trimmed.length < 64) return true;
  if (/lui\s*[-–—☆*·|]+\s*tiến/i.test(trimmed) && trimmed.length < 64) return true;
  if (/^[\s<>&«»☆\-–—|*·]+$/i.test(trimmed)) return true;
  return false;
}

function pickElementLabel(el: Element): string {
  const htmlEl = el as HTMLElement;
  const raw =
    typeof htmlEl.innerText === 'string' && htmlEl.innerText.trim()
      ? htmlEl.innerText
      : el.textContent ?? '';
  return raw.replace(/\s+/g, ' ').trim();
}

const VTQ_STORY_TITLE_SELECTORS = [
  'span.chuto40',
  '.chuto40',
  '#tieude span.chuto40',
  '#tieude .chuto40',
  '#dautrang span.chuto40',
  '#dautrang .chuto40',
  '[class~="chuto40"]',
];

/** Story name on VTQ lives in `span.chuto40` (not prev/next nav). */
export function readVtqStoryTitle(
  document: Document,
  selector?: string,
): string | undefined {
  const selectors = selector
    ? selector.split(',').map((s) => s.trim()).filter(Boolean)
    : VTQ_STORY_TITLE_SELECTORS;

  const candidates: string[] = [];

  for (const sel of selectors) {
    for (const el of document.querySelectorAll(sel)) {
      const text = pickElementLabel(el);
      if (!text || isNavigationNoiseTitle(text)) continue;
      candidates.push(text);
    }
  }

  if (candidates.length === 0) return undefined;

  // Real titles are longer than nav labels; prefer the longest distinct candidate.
  return [...new Set(candidates)].sort((a, b) => b.length - a.length)[0];
}
