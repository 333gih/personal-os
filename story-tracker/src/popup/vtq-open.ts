import browser from 'webextension-polyfill';
import { MESSAGE_TYPES } from '../shared/messages';
import type { ReadingInfo } from '../types/reading';

const RETRY_DELAYS_MS = [600, 1000, 1500, 2500, 4000];

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function openVtqChapter(info: ReadingInfo): Promise<void> {
  const chapterNumber = String(info.metadata?.chapter_number ?? '').trim();
  if (!chapterNumber) {
    window.open(info.currentUrl, '_blank', 'noopener,noreferrer');
    return;
  }

  const tab = await browser.tabs.create({ url: info.currentUrl });
  if (!tab.id) return;

  const payload = {
    chapterNumber,
    chuongid: info.metadata?.chuongid ? String(info.metadata.chuongid) : undefined,
    tuaid: info.metadata?.tuaid ? String(info.metadata.tuaid) : undefined,
  };

  for (const delay of RETRY_DELAYS_MS) {
    await sleep(delay);
    try {
      const response = await browser.tabs.sendMessage(tab.id, {
        type: MESSAGE_TYPES.RESUME_VTQ_CHAPTER,
        payload,
      });
      if (response?.success) return;
    } catch {
      /* content script not ready */
    }
  }
}

export function isVtqReading(info: ReadingInfo): boolean {
  return (
    info.metadata?.site_handler === 'vietnamthuquan' ||
    info.metadata?.site_plugin === 'vietnamthuquan'
  );
}
