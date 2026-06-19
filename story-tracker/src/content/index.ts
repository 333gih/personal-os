import browser from 'webextension-polyfill';
import { ReadingTracker } from './tracker';
import { MESSAGE_TYPES } from '../shared/messages';
import { logger } from '../utils/logger';
import { resumeVtqChapter, type VtqResumePayload } from './vtq-navigator';

const tracker = new ReadingTracker();

function init(): void {
  logger.debug('Content script loaded on', window.location.href);
  void tracker.start();

  browser.runtime.onMessage.addListener((message) => {
    if (message?.type === MESSAGE_TYPES.MANUAL_SAVE) {
      const syncMode = Boolean((message.payload as { sync?: boolean } | undefined)?.sync);
      return tracker.manualSave(syncMode);
    }
    if (message?.type === MESSAGE_TYPES.RESUME_VTQ_CHAPTER) {
      return resumeVtqChapter(message.payload as VtqResumePayload).then((ok) => ({
        success: ok,
      }));
    }
    return undefined;
  });
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}
