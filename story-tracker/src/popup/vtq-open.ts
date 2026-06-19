import browser from 'webextension-polyfill';
import {
  appendVtqResumeHash,
  buildNoidungArgFromIds,
  readTuaidFromUrl,
} from '../plugins/builtin/vietnamthuquan/muluben';
import type { ResumeChapterPayload } from '../plugins/types';
import { MESSAGE_TYPES } from '../shared/messages';
import type { ReadingInfo } from '../types/reading';

/** Retries after tab `status === complete` (content script waits for window load internally). */
const RETRY_DELAYS_MS = [0, 600, 1200, 2500, 4000, 6000, 9000, 12000];

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function waitForTabLoadComplete(tabId: number, timeoutMs = 45_000): Promise<void> {
  try {
    const tab = await browser.tabs.get(tabId);
    if (tab.status === 'complete') return;
  } catch {
    return;
  }

  await new Promise<void>((resolve) => {
    let settled = false;
    const finish = () => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      browser.tabs.onUpdated.removeListener(listener);
      resolve();
    };

    const listener: Parameters<typeof browser.tabs.onUpdated.addListener>[0] = (id, info) => {
      if (id !== tabId || info.status !== 'complete') return;
      finish();
    };

    const timer = setTimeout(finish, timeoutMs);
    browser.tabs.onUpdated.addListener(listener);
  });
}

export function buildVtqResumePayload(info: ReadingInfo): ResumeChapterPayload | null {
  const chapterNumber = String(
    info.metadata?.chapter_number ?? info.metadata?.chuongid ?? '',
  ).trim();
  if (!chapterNumber) return null;

  const chuongid = String(info.metadata?.chuongid ?? chapterNumber).trim();
  const tuaid =
    (info.metadata?.tuaid ? String(info.metadata.tuaid) : undefined) ??
    readTuaidFromUrl(info.currentUrl);

  const savedArg =
    typeof info.metadata?.noidung_arg === 'string' ? info.metadata.noidung_arg.trim() : '';
  const noidungArg =
    savedArg ||
    (tuaid && chuongid ? buildNoidungArgFromIds(tuaid, chuongid) : undefined);

  return {
    chapterNumber,
    chuongid,
    tuaid,
    noidungArg,
  };
}

export async function openVtqChapter(info: ReadingInfo): Promise<void> {
  const payload = buildVtqResumePayload(info);
  if (!payload) {
    window.open(info.currentUrl, '_blank', 'noopener,noreferrer');
    return;
  }

  const resumeUrl = appendVtqResumeHash(
    info.currentUrl,
    payload.chuongid ?? payload.chapterNumber,
    payload.tuaid,
    payload.noidungArg,
  );

  const tab = await browser.tabs.create({ url: resumeUrl });
  if (!tab.id) return;

  await waitForTabLoadComplete(tab.id);

  for (const delay of RETRY_DELAYS_MS) {
    if (delay > 0) await sleep(delay);
    try {
      const response = await browser.tabs.sendMessage(tab.id, {
        type: MESSAGE_TYPES.RESUME_VTQ_CHAPTER,
        payload,
      });
      if (response?.success) return;
    } catch {
      /* content script not ready — auto-resume from URL hash waits for page load */
    }
  }
}

export function isVtqReading(info: ReadingInfo): boolean {
  return (
    info.metadata?.site_handler === 'vietnamthuquan' ||
    info.metadata?.site_plugin === 'vietnamthuquan'
  );
}
