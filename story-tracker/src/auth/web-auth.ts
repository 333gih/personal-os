import browser from 'webextension-polyfill';
import type { WebAuthHandoffPayload } from '../config/personal-os-fe';
import { buildExtensionConnectUrl } from '../config/personal-os-fe';
import { WEB_AUTH_HANDOFF_GRACE_MS, WEB_AUTH_UI_TIMEOUT_MS } from './constants';
import { injectConnectBridge, registerConnectBridgeInjector } from './auth-connect-injector';
import { authService } from './auth-service';
import type { AuthState } from './types';
import { logger } from '../utils/logger';
import type { MessageResponse } from '../shared/messages';

const SESSION_KEYS = {
  PENDING_NONCE: 'pendingWebAuthNonce',
  PENDING_TAB_ID: 'pendingWebAuthTabId',
  PENDING_AT: 'pendingWebAuthAt',
} as const;

const LOCAL_PENDING_KEY = 'pendingWebAuth';

type PendingRecord = {
  nonce: string;
  tabId: number | null;
  at: number;
};

type PendingWebAuth = {
  nonce: string;
  tabId: number | null;
  resolve: (state: AuthState) => void;
  reject: (error: Error) => void;
  cleanup: () => void;
};

let pendingWebAuth: PendingWebAuth | null = null;
let injectorRegistered = false;

function ensureInjectorRegistered(): void {
  if (injectorRegistered) return;
  injectorRegistered = true;
  registerConnectBridgeInjector(async () => {
    const pending = await readPendingSession();
    return pending !== null;
  });
}

async function savePendingSession(nonce: string, tabId: number | null): Promise<void> {
  const record: PendingRecord = { nonce, tabId, at: Date.now() };
  await browser.storage.session.set({
    [SESSION_KEYS.PENDING_NONCE]: record.nonce,
    [SESSION_KEYS.PENDING_TAB_ID]: record.tabId,
    [SESSION_KEYS.PENDING_AT]: record.at,
  });
  await browser.storage.local.set({ [LOCAL_PENDING_KEY]: record });
}

async function readPendingSession(): Promise<{ nonce: string; tabId: number | null } | null> {
  const data = await browser.storage.session.get([
    SESSION_KEYS.PENDING_NONCE,
    SESSION_KEYS.PENDING_TAB_ID,
    SESSION_KEYS.PENDING_AT,
  ]);

  const fromSession = parsePendingRecord({
    nonce: data[SESSION_KEYS.PENDING_NONCE] as string | undefined,
    tabId: data[SESSION_KEYS.PENDING_TAB_ID] as number | null | undefined,
    at: data[SESSION_KEYS.PENDING_AT] as number | undefined,
  });
  if (fromSession) return fromSession;

  const local = await browser.storage.local.get(LOCAL_PENDING_KEY);
  const record = local[LOCAL_PENDING_KEY] as PendingRecord | undefined;
  return parsePendingRecord(record);
}

function parsePendingRecord(
  record:
    | { nonce?: string; tabId?: number | null; at?: number }
    | null
    | undefined,
): { nonce: string; tabId: number | null } | null {
  if (!record?.nonce || !record.at) return null;
  if (Date.now() - record.at > WEB_AUTH_HANDOFF_GRACE_MS) return null;
  const tabId = typeof record.tabId === 'number' ? record.tabId : null;
  return { nonce: record.nonce, tabId };
}

async function clearPendingSession(): Promise<void> {
  await browser.storage.session.remove(Object.values(SESSION_KEYS));
  await browser.storage.local.remove(LOCAL_PENDING_KEY);
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
      receivedNonce: nonce,
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

    void import('../services/pull-progress').then(({ pullRemoteProgress }) => pullRemoteProgress());
    void import('../services/sync-service').then(({ syncService }) => syncService.syncNow());

    return { success: true, data: state };
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Extension handoff failed',
    };
  }
}

export async function startPersonalOsWebAuth(): Promise<AuthState> {
  ensureInjectorRegistered();

  if (pendingWebAuth) {
    throw new Error('Personal OS sign-in is already in progress.');
  }

  const nonce = crypto.randomUUID();
  const url = buildExtensionConnectUrl(nonce);

  await clearPendingSession();
  await savePendingSession(nonce, null);

  return new Promise<AuthState>((resolve, reject) => {
    let tabId: number | null = null;
    let settled = false;

    const uiTimeout = globalThis.setTimeout(() => {
      settle(() =>
        reject(
          new Error(
            'Personal OS sign-in timed out. Complete sign-in on the web tab or try again.',
          ),
        ),
      );
    }, WEB_AUTH_UI_TIMEOUT_MS);

    const onTabRemoved = (removedTabId: number) => {
      if (tabId === null || removedTabId !== tabId) return;
      settle(
        () => reject(new Error('Personal OS sign-in tab was closed before completing.')),
        true,
      );
    };

    function settle(next: () => void, clearSession = false) {
      if (settled) return;
      settled = true;
      globalThis.clearTimeout(uiTimeout);
      browser.tabs.onRemoved.removeListener(onTabRemoved);
      pendingWebAuth = null;
      if (clearSession) {
        void clearPendingSession();
      }
      next();
    }

    function cleanup() {
      if (settled) return;
      browser.tabs.onRemoved.removeListener(onTabRemoved);
      globalThis.clearTimeout(uiTimeout);
    }

    pendingWebAuth = {
      nonce,
      tabId: null,
      resolve: (state) => settle(() => resolve(state)),
      reject: (error) => settle(() => reject(error), true),
      cleanup,
    };

    browser.tabs.onRemoved.addListener(onTabRemoved);

    void browser.tabs
      .create({ url, active: true })
      .then((tab) => {
        if (!tab.id) {
          settle(() => reject(new Error('Could not open Personal OS sign-in tab.')), true);
          return;
        }
        tabId = tab.id;
        if (pendingWebAuth?.nonce === nonce) {
          pendingWebAuth.tabId = tab.id;
        }
        void savePendingSession(nonce, tab.id);
        void injectConnectBridge(tab.id);
      })
      .catch((error) => {
        settle(
          () =>
            reject(error instanceof Error ? error : new Error('Could not open sign-in tab.')),
          true,
        );
      });
  });
}

// Register injector when background loads so SSO redirects re-inject the bridge.
ensureInjectorRegistered();
