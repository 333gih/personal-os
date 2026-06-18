import browser from 'webextension-polyfill';
import {
  EXTENSION_HANDOFF_ACK_TYPE,
  EXTENSION_HANDOFF_DOM_ID,
  EXTENSION_HANDOFF_MESSAGE_TYPE,
  type WebAuthHandoffPayload,
} from '../config/personal-os-fe';
import { MESSAGE_TYPES } from '../shared/messages';

declare global {
  interface Window {
    __PERSONAL_OS_CONNECT_BRIDGE__?: boolean;
  }
}

if (window.__PERSONAL_OS_CONNECT_BRIDGE__) {
  // Manifest + programmatic inject can both load this script.
} else {
  window.__PERSONAL_OS_CONNECT_BRIDGE__ = true;
  bootConnectBridge();
}

function bootConnectBridge(): void {
  const forwardedNonces = new Set<string>();
  const retryCounts = new Map<string, number>();

  function parsePayload(raw: string | null | undefined): WebAuthHandoffPayload | null {
    if (!raw) return null;
    try {
      return JSON.parse(raw) as WebAuthHandoffPayload;
    } catch {
      return null;
    }
  }

  function readDomHandoff(): WebAuthHandoffPayload | null {
    const el = document.getElementById(EXTENSION_HANDOFF_DOM_ID);
    return parsePayload(el?.getAttribute('data-handoff'));
  }

  async function wakeBackground(): Promise<void> {
    for (let attempt = 0; attempt < 8; attempt++) {
      try {
        await browser.runtime.sendMessage({ type: MESSAGE_TYPES.PING });
        return;
      } catch {
        await sleep(150 * (attempt + 1));
      }
    }
  }

  async function forwardHandoff(payload: WebAuthHandoffPayload): Promise<boolean> {
    const nonce = payload.nonce?.trim();
    if (!nonce || forwardedNonces.has(nonce)) return false;

    forwardedNonces.add(nonce);
    try {
      await wakeBackground();
      const response = (await browser.runtime.sendMessage({
        type: MESSAGE_TYPES.WEB_AUTH_HANDOFF,
        payload,
      })) as { success?: boolean; error?: string } | undefined;

      if (!response?.success) {
        forwardedNonces.delete(nonce);
        scheduleRetry(payload);
        return false;
      }

      window.postMessage({ type: EXTENSION_HANDOFF_ACK_TYPE }, window.location.origin);
      return true;
    } catch {
      forwardedNonces.delete(nonce);
      scheduleRetry(payload);
      return false;
    }
  }

  function scheduleRetry(payload: WebAuthHandoffPayload): void {
    const nonce = payload.nonce?.trim();
    if (!nonce) return;

    const attempts = retryCounts.get(nonce) ?? 0;
    if (attempts >= 120) return;
    retryCounts.set(nonce, attempts + 1);

    globalThis.setTimeout(() => {
      void forwardHandoff(payload);
    }, 500);
  }

  window.addEventListener('message', (event) => {
    if (event.source !== window) return;
    if (event.origin !== window.location.origin) return;

    const data = event.data as { type?: string; payload?: WebAuthHandoffPayload } | null;
    if (!data || data.type !== EXTENSION_HANDOFF_MESSAGE_TYPE || !data.payload) return;

    void forwardHandoff(data.payload);
  });

  function pollDomHandoff(): void {
    const payload = readDomHandoff();
    if (payload) {
      void forwardHandoff(payload);
    }
  }

  pollDomHandoff();

  const observer = new MutationObserver(() => {
    pollDomHandoff();
  });

  if (document.documentElement) {
    observer.observe(document.documentElement, {
      attributes: true,
      childList: true,
      subtree: true,
      attributeFilter: ['data-handoff'],
    });
  }

  let polls = 0;
  const pollTimer = globalThis.setInterval(() => {
    pollDomHandoff();
    polls += 1;
    if (polls >= 180) globalThis.clearInterval(pollTimer);
  }, 500);

  window.postMessage({ type: 'STORY_TRACKER_BRIDGE_READY' }, window.location.origin);
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => globalThis.setTimeout(resolve, ms));
}
