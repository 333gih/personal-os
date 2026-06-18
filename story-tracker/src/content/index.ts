import browser from 'webextension-polyfill';
import { ReadingTracker } from './tracker';
import { MESSAGE_TYPES } from '../shared/messages';
import { logger } from '../utils/logger';

const tracker = new ReadingTracker();

function init(): void {
  logger.debug('Content script loaded on', window.location.href);
  tracker.start();

  browser.runtime.onMessage.addListener((message) => {
    if (message?.type === MESSAGE_TYPES.MANUAL_SAVE) {
      return tracker.manualSave();
    }
    return undefined;
  });
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}
