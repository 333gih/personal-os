/**
 * WebExtension API shim for the Story Tracker iOS container app (WKWebView).
 * Replaces webextension-polyfill when TARGET=ios-app.
 */
import type { ExtensionMessage, MessageResponse } from '../shared/messages';

type StorageArea = 'local' | 'session';
type StorageChange = { oldValue?: unknown; newValue?: unknown };
type StorageListener = (
  changes: Record<string, StorageChange>,
  area: StorageArea,
) => void;

const LOCAL_KEY = 'story-tracker:local';
const SESSION_KEY = 'story-tracker:session';

const storageListeners = new Set<StorageListener>();
const messageListeners = new Set<
  (
    message: ExtensionMessage,
    sender: { id?: string },
    sendResponse: (response: MessageResponse) => void,
  ) => boolean | void
>();

function readArea(area: StorageArea): Record<string, unknown> {
  const key = area === 'local' ? LOCAL_KEY : SESSION_KEY;
  const store = area === 'local' ? localStorage : sessionStorage;
  try {
    const raw = store.getItem(key);
    return raw ? (JSON.parse(raw) as Record<string, unknown>) : {};
  } catch {
    return {};
  }
}

function writeArea(area: StorageArea, data: Record<string, unknown>): void {
  const key = area === 'local' ? LOCAL_KEY : SESSION_KEY;
  const store = area === 'local' ? localStorage : sessionStorage;
  store.setItem(key, JSON.stringify(data));
}

function emitStorageChanges(
  area: StorageArea,
  before: Record<string, unknown>,
  after: Record<string, unknown>,
): void {
  const changes: Record<string, StorageChange> = {};
  const keys = new Set([...Object.keys(before), ...Object.keys(after)]);
  for (const k of keys) {
    if (before[k] !== after[k]) {
      changes[k] = { oldValue: before[k], newValue: after[k] };
    }
  }
  if (Object.keys(changes).length === 0) return;
  for (const listener of storageListeners) {
    listener(changes, area);
  }
}

function makeStorageArea(area: StorageArea) {
  return {
    async get(keys?: string | string[] | Record<string, unknown> | null) {
      const data = readArea(area);
      if (keys == null) return { ...data };
      if (typeof keys === 'string') return { [keys]: data[keys] };
      if (Array.isArray(keys)) {
        const out: Record<string, unknown> = {};
        for (const k of keys) out[k] = data[k];
        return out;
      }
      const out: Record<string, unknown> = { ...keys };
      for (const k of Object.keys(out)) {
        if (k in data) out[k] = data[k];
      }
      return out;
    },
    async set(items: Record<string, unknown>) {
      const before = readArea(area);
      const after = { ...before, ...items };
      writeArea(area, after);
      emitStorageChanges(area, before, after);
    },
    async remove(keys: string | string[]) {
      const list = Array.isArray(keys) ? keys : [keys];
      const before = readArea(area);
      const after = { ...before };
      for (const k of list) delete after[k];
      writeArea(area, after);
      emitStorageChanges(area, before, after);
    },
    async clear() {
      const before = readArea(area);
      writeArea(area, {});
      emitStorageChanges(area, before, {});
    },
  };
}

const noopListenerApi = {
  addListener: () => {},
  removeListener: () => {},
};

const iosAppBrowser = {
  storage: {
    local: makeStorageArea('local'),
    session: makeStorageArea('session'),
    onChanged: {
      addListener(listener: StorageListener) {
        storageListeners.add(listener);
      },
      removeListener(listener: StorageListener) {
        storageListeners.delete(listener);
      },
    },
  },
  runtime: {
    id: 'ios-app',
    async sendMessage(message: ExtensionMessage): Promise<MessageResponse> {
      return new Promise((resolve) => {
        let handled = false;
        for (const listener of messageListeners) {
          const result = listener(message, { id: 'ios-app' }, (response) => {
            handled = true;
            resolve(response);
          });
          if (result === true) return;
        }
        if (!handled) {
          resolve({ success: false, error: 'No message handler registered' });
        }
      });
    },
    onMessage: {
      addListener(
        listener: (
          message: ExtensionMessage,
          sender: { id?: string },
          sendResponse: (response: MessageResponse) => void,
        ) => boolean | void,
      ) {
        messageListeners.add(listener);
      },
      removeListener(
        listener: (
          message: ExtensionMessage,
          sender: { id?: string },
          sendResponse: (response: MessageResponse) => void,
        ) => boolean | void,
      ) {
        messageListeners.delete(listener);
      },
    },
    openOptionsPage() {
      window.dispatchEvent(new CustomEvent('story-tracker-open-settings'));
    },
    getURL(path: string) {
      return path;
    },
  },
  tabs: {
    async query() {
      return [];
    },
    async sendMessage() {
      return { success: false, error: 'Save and sync on story pages run in Safari.' };
    },
    async create({ url }: { url: string; active?: boolean }) {
      window.location.assign(url);
      return { id: 1, url };
    },
    async remove() {},
    onRemoved: noopListenerApi,
    onActivated: noopListenerApi,
    onUpdated: noopListenerApi,
  },
  alarms: {
    create: async () => {},
    clear: async () => {},
    onAlarm: noopListenerApi,
  },
  scripting: {
    executeScript: async () => [],
    registerContentScripts: async () => {},
    unregisterContentScripts: async () => {},
  },
  permissions: {
    request: async () => false,
    contains: async () => false,
  },
};

export default iosAppBrowser;
