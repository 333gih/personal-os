export type ChapterClickHint = {
  chapterNumber: string;
  chapterTitle: string;
  anchorId?: string;
  chuongid?: string;
  tuaid?: string;
  clickedAt: number;
};

let activeHint: ChapterClickHint | null = null;

const CHAPTER_TEXT = /chương\s*(\d+)/i;

export function setChapterClickHint(hint: ChapterClickHint): void {
  activeHint = hint;
}

export function getChapterClickHint(): ChapterClickHint | null {
  return activeHint;
}

export function clearChapterClickHint(): void {
  activeHint = null;
}

import { extractDigits, parseNoidungFromElement } from '../plugins/builtin/vietnamthuquan/muluben';

export function parseChapterFromElement(el: Element): ChapterClickHint | null {
  const acronym = el.closest('acronym') ?? (el.tagName === 'ACRONYM' ? el : null);
  if (acronym) {
    const params = parseNoidungFromElement(acronym);
    const number =
      params.chuongid ??
      extractDigits(acronym.querySelector('.chuongso, [class*="chuongso"]')?.textContent);
    if (number) {
      return {
        chapterNumber: number,
        chapterTitle: `Chương ${number}`,
        chuongid: params.chuongid ?? number,
        tuaid: params.tuaid,
        clickedAt: Date.now(),
      };
    }
  }

  const chuongSo =
    el.classList.contains('chuongso') || el.className.includes('chuongso')
      ? el
      : el.closest('.chuongso, [class*="chuongso"]');
  if (chuongSo) {
    const number = extractDigits(chuongSo.textContent);
    if (number) {
      return {
        chapterNumber: number,
        chapterTitle: `Chương ${number}`,
        clickedAt: Date.now(),
      };
    }
  }

  const link = el.closest('a') ?? (el.tagName === 'A' ? el : null);
  const text = normalize(el.textContent);
  if (!text) return null;

  const match = text.match(CHAPTER_TEXT);
  if (!match) return null;

  let anchorId: string | undefined;
  const href = link?.getAttribute('href') ?? '';
  if (href.includes('#')) {
    anchorId = href.split('#').pop()?.trim() || undefined;
  }

  return {
    chapterNumber: match[1],
    chapterTitle: text.slice(0, 160),
    anchorId,
    clickedAt: Date.now(),
  };
}

export function isNavigationNoise(text: string): boolean {
  const t = text.trim();
  if (t.length < 3) return true;
  if (/^<<.*>>$/i.test(t)) return true;
  if (/lui/i.test(t) && /(tiến|tien|☆|-)/i.test(t)) return true;
  if (/^(lui|tiến|tien|prev|next|trước|sau)$/i.test(t)) return true;
  return false;
}

function normalize(value: string | null | undefined): string {
  return (value ?? '').replace(/\s+/g, ' ').trim();
}
