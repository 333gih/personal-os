import { getSitePlugin } from '../plugins/registry';
import type { ResumeChapterPayload } from '../plugins/types';
import {
  getMulubenContainer,
  isVtqReaderUrl,
  readVtqResumeFromHash,
} from '../plugins/builtin/vietnamthuquan/muluben';
import { logger } from '../utils/logger';

export type VtqResumePayload = ResumeChapterPayload;

/** Retries after page load — first attempt runs once VTQ scripts/catalog are ready. */
const RETRY_MS = [0, 400, 800, 1500, 2500, 4000, 6000, 9000, 12000];

const VTQ_SCRIPT_WAIT_MS = 15_000;

export function readPendingVtqResume(href = window.location.href): VtqResumePayload | null {
  const fromHash = readVtqResumeFromHash(href);
  if (!fromHash?.chuongid) return null;

  return {
    chapterNumber: fromHash.chuongid,
    chuongid: fromHash.chuongid,
    tuaid: fromHash.tuaid,
    noidungArg: fromHash.noidungArg,
  };
}

function hasNoidung1(document: Document): boolean {
  const win = document.defaultView as (Window & { noidung1?: (arg: string) => void }) | null;
  return typeof win?.noidung1 === 'function';
}

function hasMulubenCatalog(document: Document): boolean {
  const container = getMulubenContainer(document);
  return Boolean(container && container.querySelectorAll('acronym').length > 0);
}

/** Wait until the browser reports the document fully loaded (`readyState === complete`). */
export function waitForWindowLoad(
  document: Document = document,
  timeoutMs = 45_000,
): Promise<void> {
  if (document.readyState === 'complete') return Promise.resolve();

  return new Promise((resolve) => {
    const win = document.defaultView;
    if (!win) {
      resolve();
      return;
    }

    let settled = false;
    const finish = () => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      clearInterval(poll);
      win.removeEventListener('load', onLoad);
      resolve();
    };

    const onLoad = () => finish();

    const timer = setTimeout(finish, timeoutMs);
    const poll = setInterval(() => {
      if (document.readyState === 'complete') finish();
    }, 50);

    win.addEventListener('load', onLoad, { once: true });
  });
}

/**
 * After window load, wait for VTQ postback (`noidung1`) or chapter catalog (`#muluben_to`).
 * Saved `noidung_arg` still needs `noidung1` on VTQ reader pages.
 */
export async function waitForVtqTriggerReady(
  document: Document = document,
  timeoutMs = VTQ_SCRIPT_WAIT_MS,
): Promise<void> {
  await waitForWindowLoad(document);

  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    if (hasNoidung1(document)) return;
    if (hasMulubenCatalog(document)) return;
    await sleep(200);
  }

  logger.debug('VTQ trigger wait timed out; will retry resume');
}

export async function resumeVtqChapter(payload: VtqResumePayload): Promise<boolean> {
  const plugin = getSitePlugin('vietnamthuquan');
  if (!plugin?.resumeChapter) return false;

  await waitForVtqTriggerReady(document);

  for (const delay of RETRY_MS) {
    if (delay > 0) await sleep(delay);
    const ok = await plugin.resumeChapter(document, payload);
    if (ok) {
      logger.info('VTQ chapter resumed', payload);
      return true;
    }
  }

  logger.warn('VTQ chapter resume failed after retries', payload);
  return false;
}

export async function tryAutoResumeVtq(): Promise<void> {
  if (!isVtqReaderUrl(window.location.href)) return;

  const payload = readPendingVtqResume();
  if (!payload) return;

  logger.info('VTQ auto-resume scheduled from URL hash', payload);
  await resumeVtqChapter(payload);
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
