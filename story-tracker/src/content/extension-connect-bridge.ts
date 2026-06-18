import browser from 'webextension-polyfill';
import {
  EXTENSION_HANDOFF_ACK_TYPE,
  EXTENSION_HANDOFF_DOM_ID,
  EXTENSION_HANDOFF_MESSAGE_TYPE,
  type WebAuthHandoffPayload,
} from '../config/personal-os-fe';
import { MESSAGE_TYPES } from '../shared/messages';

const forwardedNonces = new Set<string>();

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

async function forwardHandoff(payload: WebAuthHandoffPayload): Promise<boolean> {
  const nonce = payload.nonce?.trim();
  if (!nonce || forwardedNonces.has(nonce)) return false;

  forwardedNonces.add(nonce);
  try {
    const response = (await browser.runtime.sendMessage({
      type: MESSAGE_TYPES.WEB_AUTH_HANDOFF,
      payload,
    })) as { success?: boolean } | undefined;
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

const retryCounts = new Map<string, number>();

function scheduleRetry(payload: WebAuthHandoffPayload): void {
  const nonce = payload.nonce?.trim();
  if (!nonce) return;

  const attempts = retryCounts.get(nonce) ?? 0;
  if (attempts >= 40) return;
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
} else {
  document.addEventListener('DOMContentLoaded', () => {
    observer.observe(document.documentElement, {
      attributes: true,
      childList: true,
      subtree: true,
      attributeFilter: ['data-handoff'],
    });
    pollDomHandoff();
  });
}

// Retry DOM read for late React hydration.
let polls = 0;
const pollTimer = globalThis.setInterval(() => {
  pollDomHandoff();
  polls += 1;
  if (polls >= 60) globalThis.clearInterval(pollTimer);
}, 500);
