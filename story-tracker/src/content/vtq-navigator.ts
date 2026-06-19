import { getSitePlugin } from '../plugins/registry';
import type { ResumeChapterPayload } from '../plugins/types';

const RETRY_MS = [0, 400, 800, 1200, 2000];

export type VtqResumePayload = ResumeChapterPayload;

export async function resumeVtqChapter(payload: VtqResumePayload): Promise<boolean> {
  const plugin = getSitePlugin('vietnamthuquan');
  if (!plugin?.resumeChapter) return false;

  for (const delay of RETRY_MS) {
    if (delay > 0) await sleep(delay);
    const ok = await plugin.resumeChapter(document, payload);
    if (ok) return true;
  }
  return false;
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
