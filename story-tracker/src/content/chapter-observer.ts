import type { SiteProfile, SiteProfileSelectors } from '../types/site-profile';
import { findChapterListRoots } from '../parsers/dom-crawler';
import { getBuiltinProfiles, matchProfile } from '../config/site-profile-builtin';
import {
  parseChapterFromElement,
  setChapterClickHint,
  isNavigationNoise,
} from './chapter-hint';

export type ChapterChangeCallback = () => void;

/** Watch DOM chapter lists / content for SPA readers (e.g. Vietnam Thu Quan). */
export class ChapterObserver {
  private observers: MutationObserver[] = [];
  private debounceTimer: ReturnType<typeof setTimeout> | null = null;

  constructor(
    private readonly onChapterChange: ChapterChangeCallback,
    private readonly debounceMs = 400,
  ) {}

  start(): void {
    this.stop();
    const profile = matchProfile(window.location.href, getBuiltinProfiles());
    const selectors = profile?.selectors ?? {};

    const roots = findChapterListRoots(document, selectors);
    for (const root of roots) {
      const observer = new MutationObserver(() => this.schedule());
      observer.observe(root, {
        subtree: true,
        childList: true,
        attributes: true,
        attributeFilter: ['class', 'aria-current', 'href', 'selected'],
      });
      this.observers.push(observer);
    }

    for (const sel of selectors.contentRoot ?? ['#noidung', '.chapter-c', 'article', 'main']) {
      const el = document.querySelector(sel);
      if (!el) continue;
      const observer = new MutationObserver(() => this.schedule());
      observer.observe(el, { subtree: true, childList: true, characterData: true });
      this.observers.push(observer);
    }

    for (const sel of ['#tieude', '#dautrang', '#tieudechuong', 'span.chuto40', '.chuto40']) {
      const el = document.querySelector(sel);
      if (!el) continue;
      const observer = new MutationObserver(() => this.schedule());
      observer.observe(el, { subtree: true, childList: true, characterData: true });
      this.observers.push(observer);
    }

    document.addEventListener('click', this.onClick, true);
    document.addEventListener('keydown', this.onKeyDown, true);
    document.addEventListener('change', this.onSelectChange, true);
    window.addEventListener('popstate', this.onPopState);
  }

  stop(): void {
    for (const observer of this.observers) observer.disconnect();
    this.observers = [];
    document.removeEventListener('click', this.onClick, true);
    document.removeEventListener('keydown', this.onKeyDown, true);
    document.removeEventListener('change', this.onSelectChange, true);
    window.removeEventListener('popstate', this.onPopState);
    if (this.debounceTimer) clearTimeout(this.debounceTimer);
  }

  private onSelectChange = (event: Event): void => {
    const target = event.target as Element | null;
    if (!target || target.tagName !== 'SELECT') return;
    this.scheduleSoon();
  };

  private onPopState = (): void => {
    this.schedule();
  };

  private onKeyDown = (event: KeyboardEvent): void => {
    if (this.isTypingInField(event.target)) return;

    const chapterNavKeys = new Set([
      'ArrowLeft',
      'ArrowRight',
      'PageUp',
      'PageDown',
      'Home',
      'End',
    ]);

    if (chapterNavKeys.has(event.key)) {
      this.schedule();
      return;
    }

    // Common reader shortcuts (n/p, [, ]) when site does not use input focus
    if (!event.ctrlKey && !event.metaKey && !event.altKey) {
      if (event.key === 'n' || event.key === 'p' || event.key === '[' || event.key === ']') {
        this.schedule();
      }
    }
  };

  private isTypingInField(target: EventTarget | null): boolean {
    const el = target as Element | null;
    if (!el) return false;
    return Boolean(
      el.closest('input, textarea, select, [contenteditable="true"], [role="textbox"]'),
    );
  }

  private onClick = (event: Event): void => {
    const target = event.target as Element | null;
    if (!target) return;

    const hint = parseChapterFromElement(target);
    if (hint) {
      setChapterClickHint(hint);
      this.scheduleSoon();
      return;
    }

    const navHit = target.closest(
      [
        'a',
        'button',
        'li',
        'option',
        '.chuongso',
        '[class*="chuong"]',
        'acronym',
        '[onclick*="noidung"]',
        '[class*="chapter"]',
        '[class*="next"]',
        '[class*="prev"]',
        '[class*="ke-tiep"]',
        '[class*="truoc"]',
        '.menu',
        '.pagination',
        '.chapter-nav',
        '.nav-chapter',
      ].join(', '),
    );

    const navText = normalizeNavText(navHit?.textContent ?? target.textContent);
    if (navHit && navText && !isNavigationNoise(navText)) {
      this.schedule();
      return;
    }

    if (navHit && (target.closest('[class*="ke-tiep"]') || target.closest('[class*="truoc"]'))) {
      this.scheduleSoon();
    }
  };

  private scheduleSoon(): void {
    if (this.debounceTimer) clearTimeout(this.debounceTimer);
    this.debounceTimer = setTimeout(() => {
      this.debounceTimer = null;
      this.onChapterChange();
    }, 700);
  }

  private schedule(): void {
    if (this.debounceTimer) clearTimeout(this.debounceTimer);
    this.debounceTimer = setTimeout(() => {
      this.debounceTimer = null;
      this.onChapterChange();
    }, this.debounceMs);
  }
}

function normalizeNavText(value: string | null | undefined): string {
  return (value ?? '').replace(/\s+/g, ' ').trim();
}
