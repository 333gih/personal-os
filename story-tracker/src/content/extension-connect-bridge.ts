import browser from 'webextension-polyfill';
import { EXTENSION_HANDOFF_MESSAGE_TYPE } from '../config/personal-os-fe';

window.addEventListener('message', (event) => {
  if (event.source !== window) return;
  if (event.origin !== window.location.origin) return;

  const data = event.data as { type?: string; payload?: unknown } | null;
  if (!data || data.type !== EXTENSION_HANDOFF_MESSAGE_TYPE) return;

  void browser.runtime.sendMessage({
    type: 'WEB_AUTH_HANDOFF',
    payload: data.payload,
  });
});
