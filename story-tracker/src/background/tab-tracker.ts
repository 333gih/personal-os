import browser from 'webextension-polyfill';
import { logger } from '../utils/logger';

export class TabTracker {
  private activeTabId: number | null = null;

  init(): void {
    browser.tabs.onActivated.addListener(({ tabId }) => {
      this.activeTabId = tabId;
      logger.debug('Active tab changed:', tabId);
    });

    browser.tabs.onRemoved.addListener((tabId) => {
      if (this.activeTabId === tabId) {
        this.activeTabId = null;
      }
    });

    void browser.tabs.query({ active: true, currentWindow: true }).then(([tab]) => {
      if (tab?.id) this.activeTabId = tab.id;
    });
  }

  getActiveTabId(): number | null {
    return this.activeTabId;
  }
}

export const tabTracker = new TabTracker();
