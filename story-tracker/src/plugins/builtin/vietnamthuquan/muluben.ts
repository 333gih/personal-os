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

export function buildNoidungArgFromIds(tuaid: string, chuongid: string): string {
  return `tuaid=${tuaid}&chuongid=${chuongid}`;
}

/** `tuaid` query param on VTQ reader URLs (e.g. truyen.aspx?tid=…&tuaid=33083). */
export function readTuaidFromUrl(url: string): string | undefined {
  try {
    const parsed = new URL(url);
    for (const key of ['tuaid', 'Tuaid', 'TUAID']) {
      const value = parsed.searchParams.get(key)?.trim();
      if (value && /^\d+$/.test(value)) return value;
    }
  } catch {
    return undefined;
  }
  return undefined;
}

export function readTuaidFromCatalog(document: Document): string | undefined {
  for (const entry of collectMulubenAcronyms(document)) {
    if (entry.tuaid) return entry.tuaid;
  }
  return undefined;
}

function getNoidungWindow(document: Document): (Window & { noidung1?: (arg: string) => void }) | null {
  return (document.defaultView ?? globalThis.window) as
    | (Window & { noidung1?: (arg: string) => void })
    | null;
}

function findNoidungClickTarget(
  document: Document,
  tuaid: string | undefined,
  chuongid: string,
  arg: string,
): HTMLElement | null {
  const container = getMulubenContainer(document);
  if (!container) return null;

  for (const acronym of container.querySelectorAll('acronym')) {
    const onclick =
      acronym.getAttribute('onclick') ??
      acronym.querySelector('[onclick*="noidung"]')?.getAttribute('onclick') ??
      '';
    if (onclick.includes(arg)) {
      return (
        (acronym.querySelector('[onclick*="noidung"]') as HTMLElement | null) ??
        (acronym.querySelector('div') as HTMLElement | null) ??
        (acronym as HTMLElement)
      );
    }
  }

  for (const acronym of container.querySelectorAll('acronym')) {
    const params = parseNoidungFromElement(acronym);
    const displayNumber = extractDigits(
      acronym.querySelector('.chuongso, [class*="chuongso"]')?.textContent,
    );
    const cid = params.chuongid ?? displayNumber;
    if (cid !== chuongid) continue;
    if (tuaid && params.tuaid && params.tuaid !== tuaid) continue;

    return (
      (acronym.querySelector('[onclick*="noidung"]') as HTMLElement | null) ??
      (acronym.querySelector('div') as HTMLElement | null) ??
      (acronym as HTMLElement)
    );
  }

  return null;
}

/** Invoke VTQ postback with the exact onclick argument string. */
export function invokeNoidungRaw(document: Document, arg: string): boolean {
  const normalized = arg.trim();
  if (!normalized) return false;

  const win = getNoidungWindow(document);
  if (typeof win?.noidung1 === 'function') {
    win.noidung1(normalized);
    return true;
  }

  const params = parseNoidungOnclick(`noidung1('${normalized}')`);
  const chuongid = params.chuongid ?? '';
  if (!chuongid) return false;

  const clickTarget = findNoidungClickTarget(document, params.tuaid, chuongid, normalized);
  if (clickTarget) {
    clickTarget.click();
    return true;
  }

  return false;
}

export function parseVtqResumeToken(token: string): {
  chuongid: string;
  tuaid?: string;
  noidungArg?: string;
} | null {
  const decoded = decodeURIComponent(token).trim();
  if (!decoded) return null;

  if (/tuaid=/i.test(decoded) && /chuongid=/i.test(decoded)) {
    const params = parseNoidungOnclick(`noidung1('${decoded}')`);
    if (!params.chuongid) return null;
    return {
      chuongid: params.chuongid,
      tuaid: params.tuaid,
      noidungArg: decoded,
    };
  }

  const [chuongid, tuaid] = decoded.split(':');
  if (!chuongid) return null;
  return {
    chuongid,
    tuaid: tuaid || undefined,
    noidungArg: tuaid ? buildNoidungArgFromIds(tuaid, chuongid) : undefined,
  };
}

export function readVtqResumeFromHash(url: string): {
  chuongid: string;
  tuaid?: string;
  noidungArg?: string;
} | null {
  const match = url.match(/[#&]st_resume=([^&]+)/i);
  if (!match?.[1]) return null;
  return parseVtqResumeToken(match[1]);
}

export function appendVtqResumeHash(
  url: string,
  chuongid: string,
  tuaid?: string,
  noidungArg?: string,
): string {
  try {
    const parsed = new URL(url);
    const token = noidungArg
      ? encodeURIComponent(noidungArg)
      : tuaid
        ? encodeURIComponent(`${chuongid}:${tuaid}`)
        : encodeURIComponent(chuongid);

    let hash = parsed.hash.replace(/^#/, '');
    hash = hash.replace(/&?st_resume=[^&]*/gi, '').replace(/^&+|&+$/g, '');
    parsed.hash = hash ? `${hash}&st_resume=${token}` : `st_resume=${token}`;
    return parsed.href;
  } catch {
    return url;
  }
}

export function isVtqReaderUrl(url: string): boolean {
  return /vietnamthuquan|thuquansach/i.test(url) && /truyen\.aspx/i.test(url);
}

/** Invoke VTQ postback reader for an exact tuaid + chuongid pair. */
export function invokeNoidung1(
  document: Document,
  tuaid: string,
  chuongid: string,
): boolean {
  const arg = buildNoidungArgFromIds(tuaid, chuongid);
  const win = getNoidungWindow(document);

  if (typeof win?.noidung1 === 'function') {
    win.noidung1(arg);
    return true;
  }

  const clickTarget = findNoidungClickTarget(document, tuaid, chuongid, arg);
  if (clickTarget) {
    clickTarget.click();
    return true;
  }

  return false;
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
  tuaid?: string,
  noidungArg?: string,
): boolean {
  const savedArg = noidungArg?.trim();
  if (savedArg && invokeNoidungRaw(document, savedArg)) {
    return true;
  }

  const resolvedChuongid = chuongid ?? chapterNumber;
  const pageUrl = document.defaultView?.location?.href;
  const resolvedTuaid =
    tuaid ??
    (pageUrl ? readTuaidFromUrl(pageUrl) : undefined) ??
    readTuaidFromCatalog(document);

  if (resolvedTuaid && resolvedChuongid) {
    if (invokeNoidung1(document, resolvedTuaid, resolvedChuongid)) {
      return true;
    }
  }

  const container = getMulubenContainer(document);
  if (!container) return false;

  if (typeof container.scrollIntoView === 'function') {
    container.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
  }

  const entry = findMulubenEntry(document, chapterNumber, chuongid);
  if (!entry) return false;

  const entryArg = buildNoidungArg(entry);
  if (entryArg && invokeNoidungRaw(document, entryArg)) {
    return true;
  }

  const entryTuaid = entry.tuaid ?? resolvedTuaid;
  if (entryTuaid && entry.chuongid) {
    if (invokeNoidung1(document, entryTuaid, entry.chuongid)) {
      return true;
    }
  }

  if (entryArg) {
    const clickTarget = findNoidungClickTarget(document, entry.tuaid, entry.chuongid, entryArg);
    if (clickTarget) {
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
