import type { ReadingHistoryEntry, ReadingSession, SyncStatus } from './reading';
import type { AuthState } from '../auth/types';

export interface StoryCatalogEntry {
  storyId: string;
  storyTitle: string;
  siteId: string;
  hostname: string;
  lastChapterId?: string;
  lastChapterTitle?: string;
  lastReadAt: number;
  lastProgress: number;
  currentUrl: string;
}

export interface StorageSchema {
  auth: AuthState | null;
  unsyncedEvents: UnsyncedEvent[];
  parserCache: Record<string, ParserCacheEntry>;
  readingSessions: Record<string, ReadingSession>;
  readingHistory: ReadingHistoryEntry[];
  storyCatalog: Record<string, StoryCatalogEntry>;
  syncStatus: SyncStatus;
  settings: ExtensionSettings;
}

export interface UnsyncedEvent {
  id: string;
  payload: import('./api').ReadingProgressPayload;
  createdAt: number;
  retryCount: number;
  lastAttemptAt?: number;
}

export interface ParserCacheEntry {
  siteId: string;
  lastUrl: string;
  cachedAt: number;
  data: Record<string, unknown>;
}

import type { CustomOrigin } from './site-registry';

import type { CustomSiteProfile } from './site-profile';

export interface ExtensionSettings {
  syncIntervalMs: number;
  enabledSites: Record<string, boolean>;
  autoSync: boolean;
  autoDiscoverSites: boolean;
  customOrigins: CustomOrigin[];
  /** User-defined site profiles (URL rules + optional DOM selectors). */
  customProfiles: CustomSiteProfile[];
}

export const DEFAULT_SETTINGS: ExtensionSettings = {
  syncIntervalMs: __DEFAULT_SYNC_INTERVAL_MS__,
  enabledSites: {},
  autoSync: true,
  autoDiscoverSites: true,
  customOrigins: [],
  customProfiles: [],
};

export const STORAGE_KEYS = {
  AUTH: 'auth',
  UNSYNCED_EVENTS: 'unsyncedEvents',
  PARSER_CACHE: 'parserCache',
  READING_SESSIONS: 'readingSessions',
  READING_HISTORY: 'readingHistory',
  STORY_CATALOG: 'storyCatalog',
  SYNC_STATUS: 'syncStatus',
  SETTINGS: 'settings',
} as const;
