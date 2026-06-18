import browser from 'webextension-polyfill';
import type { WebAuthHandoffPayload } from '../config/personal-os-fe';
import { buildExtensionConnectUrl } from '../config/personal-os-fe';
import { authService } from './auth-service';
import type { AuthState } from './types';
import { logger } from '../utils/logger';
import type { MessageResponse } from '../shared/messages';

const WEB_AUTH_TIMEOUT_MS = 5 * 60 * 1000;

const SESSION_KEYS = {
  PENDING_NONCE: 'pendingWebAuthNonce',
  PENDING_TAB_ID: 'pendingWebAuthTabId',
  PENDING_AT: 'pendingWebAuthAt',
} as const;

type PendingWebAuth = {
  nonce: string;
  tabId: number | null;
  resolve: (state: AuthState) => void;
  reject: (error: Error) => void;
  cleanup: () => void;
};

let pendingWebAuth: PendingWebAuth | null = null;

async function savePendingSession(nonce: string, tabId: number | null): Promise<void> {
  await browser.storage.session.set({
    [SESSION_KEYS.PENDING_NONCE]: nonce,
    [SESSION_KEYS.PENDING_TAB_ID]: tabId,
    [SESSION_KEYS.PENDING_AT]: Date.now(),
  });
}

async function readPendingSession(): Promise<{ nonce: string; tabId: number | null } | null> {
  const data = await browser.storage.session.get([
    SESSION_KEYS.PENDING_NONCE,
    SESSION_KEYS.PENDING_TAB_ID,
    SESSION_KEYS.PENDING_AT,
  ]);
  const nonce = data[SESSION_KEYS.PENDING_NONCE] as string | undefined;
  const at = data[SESSION_KEYS.PENDING_AT] as number | undefined;
  if (!nonce || !at || Date.now() - at > WEB_AUTH_TIMEOUT_MS) {
    return null;
  }
  const tabId = data[SESSION_KEYS.PENDING_TAB_ID] as number | undefined;
  return { nonce, tabId: typeof tabId === 'number' ? tabId : null };
}

async function clearPendingSession(): Promise<void> {
  await browser.storage.session.remove(Object.values(SESSION_KEYS));
}

async function closeHandoffTab(tabId: number | null): Promise<void> {
  if (tabId === null) return;
  try {
    await browser.tabs.remove(tabId);
  } catch {
    // tab may already be closed
  }
}

export async function processWebAuthHandoff(
  payload: WebAuthHandoffPayload,
): Promise<MessageResponse<AuthState>> {
  const nonce = payload.nonce?.trim();
  if (!nonce) {
    return { success: false, error: 'Missing handoff nonce.' };
  }

  const session = await readPendingSession();
  const active = pendingWebAuth;
  const expectedNonce = active?.nonce ?? session?.nonce ?? null;

  if (!expectedNonce || expectedNonce !== nonce) {
    logger.warn('Ignored extension handoff with mismatched or missing pending sign-in', {
      hasActive: Boolean(active),
      hasSession: Boolean(session),
    });
    return { success: false, error: 'No active Personal OS sign-in for this handoff.' };
  }

  try {
    const state = await authService.completeWebHandoff(payload);
    const tabId = active?.tabId ?? session?.tabId ?? null;
    await closeHandoffTab(tabId);
    await clearPendingSession();

    if (active && active.nonce === nonce) {
      active.cleanup();
      active.resolve(state);
      pendingWebAuth = null;
    }

    return { success: true, data: state };
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Extension handoff failed',
    };
  }
}

export async function startPersonalOsWebAuth(): Promise<AuthState> {
  if (pendingWebAuth) {
    throw new Error('Personal OS sign-in is already in progress.');
  }

  const nonce = crypto.randomUUID();
  const url = buildExtensionConnectUrl(nonce);

  await savePendingSession(nonce, null);

  return new Promise<AuthState>((resolve, reject) => {
    let tabId: number | null = null;
    let settled = false;

    const timeout = globalThis.setTimeout(() => {
      finish(() => reject(new Error('Personal OS sign-in timed out. Please try again.')));
    }, WEB_AUTH_TIMEOUT_MS);

    const onTabRemoved = (removedTabId: number) => {
      if (tabId === null || removedTabId !== tabId) return;
      finish(() =>
        reject(new Error('Personal OS sign-in tab was closed before completing.')),
      );
    };

    function finish(next: () => void) {
      if (settled) return;
      settled = true;
      globalThis.clearTimeout(timeout);
      browser.tabs.onRemoved.removeListener(onTabRemoved);
      pendingWebAuth = null;
      void clearPendingSession();
      next();
    }

    function cleanup() {
      if (settled) return;
      browser.tabs.onRemoved.removeListener(onTabRemoved);
      globalThis.clearTimeout(timeout);
    }

    pendingWebAuth = {
      nonce,
      tabId: null,
      resolve: (state) => finish(() => resolve(state)),
      reject: (error) => finish(() => reject(error)),
      cleanup,
    };

    browser.tabs.onRemoved.addListener(onTabRemoved);

    void browser.tabs
      .create({ url, active: true })
      .then((tab) => {
        if (!tab.id) {
          finish(() => reject(new Error('Could not open Personal OS sign-in tab.')));
          return;
        }
        tabId = tab.id;
        if (pendingWebAuth?.nonce === nonce) {
          pendingWebAuth.tabId = tab.id;
        }
        void savePendingSession(nonce, tab.id);
      })
      .catch((error) => {
        finish(() =>
          reject(error instanceof Error ? error : new Error('Could not open sign-in tab.')),
        );
      });
  });
}
