import browser from 'webextension-polyfill';
import type { StorageSchema, ExtensionSettings } from '../types/storage';
import {
  DEFAULT_SETTINGS,
  STORAGE_KEYS,
} from '../types/storage';
import type { AuthState } from '../auth/types';
import type { ReadingHistoryEntry, ReadingSession, SyncStatus } from '../types/reading';
import type { UnsyncedEvent } from '../types/storage';
import { GUEST_MAX_STORIES, MAX_HISTORY_ENTRIES } from '../shared/constants';

const DEFAULT_SYNC_STATUS: SyncStatus = {
  state: 'idle',
  lastSyncAt: null,
  pendingCount: 0,
};

export class StorageService {
  async get<K extends keyof StorageSchema>(key: K): Promise<StorageSchema[K]> {
    const result = await browser.storage.local.get(key);
    return (result[key] as StorageSchema[K]) ?? this.getDefault(key);
  }

  async set<K extends keyof StorageSchema>(
    key: K,
    value: StorageSchema[K],
  ): Promise<void> {
    await browser.storage.local.set({ [key]: value });
  }

  async update<K extends keyof StorageSchema>(
    key: K,
    updater: (current: StorageSchema[K]) => StorageSchema[K],
  ): Promise<StorageSchema[K]> {
    const current = await this.get(key);
    const next = updater(current);
    await this.set(key, next);
    return next;
  }

  async getAuth(): Promise<AuthState | null> {
    return this.get(STORAGE_KEYS.AUTH);
  }

  async setAuth(auth: AuthState | null): Promise<void> {
    await this.set(STORAGE_KEYS.AUTH, auth);
  }

  async getSettings(): Promise<ExtensionSettings> {
    const raw = await this.get(STORAGE_KEYS.SETTINGS);
    return {
      ...DEFAULT_SETTINGS,
      ...raw,
      customProfiles: raw.customProfiles ?? [],
    };
  }

  async getSyncStatus(): Promise<SyncStatus> {
    return this.get(STORAGE_KEYS.SYNC_STATUS);
  }

  async setSyncStatus(status: SyncStatus): Promise<void> {
    await this.set(STORAGE_KEYS.SYNC_STATUS, status);
  }

  async getUnsyncedEvents(): Promise<UnsyncedEvent[]> {
    return this.get(STORAGE_KEYS.UNSYNCED_EVENTS);
  }

  async addUnsyncedEvent(event: UnsyncedEvent): Promise<void> {
    await this.update(STORAGE_KEYS.UNSYNCED_EVENTS, (events) => [...events, event]);
  }

  async removeUnsyncedEvents(ids: string[]): Promise<void> {
    const idSet = new Set(ids);
    await this.update(STORAGE_KEYS.UNSYNCED_EVENTS, (events) =>
      events.filter((e) => !idSet.has(e.id)),
    );
  }

  async upsertReadingSession(session: ReadingSession): Promise<void> {
    const storyId = session.readingInfo.storyId;
    await this.update(STORAGE_KEYS.READING_SESSIONS, (sessions) => {
      const pruned = Object.fromEntries(
        Object.entries(sessions).filter(([, value]) => value.readingInfo.storyId !== storyId),
      );
      return {
        ...pruned,
        [storyId]: { ...session, id: storyId },
      };
    });
  }

  async upsertStoryCatalog(entry: ReadingHistoryEntry): Promise<void> {
    await this.update(STORAGE_KEYS.STORY_CATALOG, (catalog) => ({
      ...catalog,
      [entry.storyId]: {
        storyId: entry.storyId,
        storyTitle: entry.storyTitle,
        siteId: entry.siteId,
        hostname: safeHostname(entry.currentUrl),
        lastChapterId: entry.chapterId,
        lastChapterTitle: entry.chapterTitle,
        lastReadAt: entry.lastReadAt,
        lastProgress: entry.progress.percentage,
        currentUrl: entry.currentUrl,
      },
    }));
  }

  async addHistoryEntry(entry: ReadingHistoryEntry): Promise<void> {
    const auth = await this.getAuth();
    const maxEntries = auth ? MAX_HISTORY_ENTRIES : GUEST_MAX_STORIES;
    await this.update(STORAGE_KEYS.READING_HISTORY, (history) => {
      const filtered = history.filter((h) => h.storyId !== entry.storyId);
      return [entry, ...filtered].slice(0, maxEntries);
    });
    await this.upsertStoryCatalog(entry);
  }

  async removeStoryProgress(storyId: string): Promise<void> {
    await this.update(STORAGE_KEYS.READING_SESSIONS, (sessions) => {
      const next = { ...sessions };
      delete next[storyId];
      return next;
    });
    await this.update(STORAGE_KEYS.READING_HISTORY, (history) =>
      history.filter((h) => h.storyId !== storyId),
    );
    await this.update(STORAGE_KEYS.STORY_CATALOG, (catalog) => {
      const next = { ...catalog };
      delete next[storyId];
      return next;
    });
  }

  async getReadingHistory(): Promise<ReadingHistoryEntry[]> {
    return this.get(STORAGE_KEYS.READING_HISTORY);
  }

  async clearReadingHistory(): Promise<void> {
    await browser.storage.local.remove([
      STORAGE_KEYS.READING_HISTORY,
      STORAGE_KEYS.STORY_CATALOG,
      STORAGE_KEYS.READING_SESSIONS,
    ]);
  }

  async clearCache(): Promise<void> {
    await browser.storage.local.remove([
      STORAGE_KEYS.PARSER_CACHE,
      STORAGE_KEYS.READING_SESSIONS,
      STORAGE_KEYS.UNSYNCED_EVENTS,
    ]);
  }

  async exportAll(): Promise<StorageSchema> {
    const keys = Object.values(STORAGE_KEYS);
    const data = await browser.storage.local.get(keys);
    return {
      auth: (data[STORAGE_KEYS.AUTH] as AuthState | null) ?? null,
      unsyncedEvents: (data[STORAGE_KEYS.UNSYNCED_EVENTS] as UnsyncedEvent[]) ?? [],
      parserCache: (data[STORAGE_KEYS.PARSER_CACHE] as StorageSchema['parserCache']) ?? {},
      readingSessions:
        (data[STORAGE_KEYS.READING_SESSIONS] as StorageSchema['readingSessions']) ?? {},
      readingHistory: (data[STORAGE_KEYS.READING_HISTORY] as ReadingHistoryEntry[]) ?? [],
      storyCatalog: (data[STORAGE_KEYS.STORY_CATALOG] as StorageSchema['storyCatalog']) ?? {},
      syncStatus: (data[STORAGE_KEYS.SYNC_STATUS] as SyncStatus) ?? DEFAULT_SYNC_STATUS,
      settings: (data[STORAGE_KEYS.SETTINGS] as ExtensionSettings) ?? DEFAULT_SETTINGS,
    };
  }

  private getDefault<K extends keyof StorageSchema>(key: K): StorageSchema[K] {
    switch (key) {
      case STORAGE_KEYS.AUTH:
        return null as StorageSchema[K];
      case STORAGE_KEYS.UNSYNCED_EVENTS:
        return [] as StorageSchema[K];
      case STORAGE_KEYS.PARSER_CACHE:
        return {} as StorageSchema[K];
      case STORAGE_KEYS.READING_SESSIONS:
        return {} as StorageSchema[K];
      case STORAGE_KEYS.READING_HISTORY:
        return [] as StorageSchema[K];
      case STORAGE_KEYS.STORY_CATALOG:
        return {} as StorageSchema[K];
      case STORAGE_KEYS.SYNC_STATUS:
        return DEFAULT_SYNC_STATUS as StorageSchema[K];
      case STORAGE_KEYS.SETTINGS:
        return DEFAULT_SETTINGS as StorageSchema[K];
      default:
        throw new Error(`Unknown storage key: ${key}`);
    }
  }
}

export const storageService = new StorageService();

function safeHostname(url: string): string {
  try {
    return new URL(url).hostname;
  } catch {
    return '';
  }
}
