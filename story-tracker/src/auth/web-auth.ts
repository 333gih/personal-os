import browser from 'webextension-polyfill';
import type { WebAuthHandoffPayload } from '../config/personal-os-fe';
import { buildExtensionConnectUrl } from '../config/personal-os-fe';
import { authService } from './auth-service';
import type { AuthState } from './types';
import { logger } from '../utils/logger';

const WEB_AUTH_TIMEOUT_MS = 5 * 60 * 1000;

export async function startPersonalOsWebAuth(): Promise<AuthState> {
  const nonce = crypto.randomUUID();
  const url = buildExtensionConnectUrl(nonce);

  const tab = await browser.tabs.create({ url, active: true });
  if (!tab.id) {
    throw new Error('Could not open Personal OS sign-in tab.');
  }

  return new Promise<AuthState>((resolve, reject) => {
    const tabId = tab.id!;

    const timeout = globalThis.setTimeout(() => {
      cleanup();
      reject(new Error('Personal OS sign-in timed out. Please try again.'));
    }, WEB_AUTH_TIMEOUT_MS);

    const onMessage = (message: { type?: string; payload?: WebAuthHandoffPayload }) => {
      if (message?.type !== 'WEB_AUTH_HANDOFF' || !message.payload) return;

      const payload = message.payload;
      if (!payload.nonce || payload.nonce !== nonce) {
        logger.warn('Ignored extension handoff with mismatched nonce');
        return;
      }

      void (async () => {
        try {
          const state = await authService.completeWebHandoff(payload);
          cleanup();
          try {
            await browser.tabs.remove(tabId);
          } catch {
            // tab may already be closed
          }
          resolve(state);
        } catch (error) {
          cleanup();
          reject(error instanceof Error ? error : new Error('Extension handoff failed'));
        }
      })();
    };

    const onTabRemoved = (removedTabId: number) => {
      if (removedTabId !== tabId) return;
      cleanup();
      reject(new Error('Personal OS sign-in tab was closed before completing.'));
    };

    function cleanup() {
      globalThis.clearTimeout(timeout);
      browser.runtime.onMessage.removeListener(onMessage);
      browser.tabs.onRemoved.removeListener(onTabRemoved);
    }

    browser.runtime.onMessage.addListener(onMessage);
    browser.tabs.onRemoved.addListener(onTabRemoved);
  });
}
