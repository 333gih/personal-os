import browser from 'webextension-polyfill';
import { getPersonalOsFeOrigin } from '../config/personal-os-fe';
import { logger } from '../utils/logger';

const BRIDGE_FILE = 'src/content/extension-connect-bridge.js';

const injectedTabs = new Set<number>();

export function isExtensionConnectUrl(url: string): boolean {
  try {
    const parsed = new URL(url);
    if (!parsed.pathname.startsWith('/extension/connect')) return false;

    const feOrigin = getPersonalOsFeOrigin();
    if (parsed.origin === feOrigin) return true;

    const host = parsed.hostname;
    if (host === 'localhost' || host === '127.0.0.1') {
      return parsed.protocol === 'http:' || parsed.protocol === 'https:';
    }

    return false;
  } catch {
    return false;
  }
}

export async function injectConnectBridge(tabId: number): Promise<boolean> {
  if (injectedTabs.has(tabId)) return true;

  try {
    await browser.scripting.executeScript({
      target: { tabId },
      files: [BRIDGE_FILE],
    });
    injectedTabs.add(tabId);
    logger.info('Injected extension connect bridge', { tabId });
    return true;
  } catch (error) {
    logger.warn('Connect bridge injection failed', { tabId, error });
    return false;
  }
}

export function registerConnectBridgeInjector(
  hasPendingSignIn: () => Promise<boolean>,
): void {
  browser.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
    if (changeInfo.status !== 'complete' || !tab.url || !isExtensionConnectUrl(tab.url)) {
      return;
    }

    void hasPendingSignIn().then((pending) => {
      if (!pending) return;
      void injectConnectBridge(tabId);
    });
  });

  browser.tabs.onRemoved.addListener((tabId) => {
    injectedTabs.delete(tabId);
  });
}
