import type { ReadingHistoryEntry, ReadingSession, SyncStatus } from './reading';
import type { AuthState } from '../auth/types';

export interface StorageSchema {
  auth: AuthState | null;
  unsyncedEvents: UnsyncedEvent[];
  parserCache: Record<string, ParserCacheEntry>;
  readingSessions: Record<string, ReadingSession>;
  readingHistory: ReadingHistoryEntry[];
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

export interface ExtensionSettings {
  syncIntervalMs: number;
  enabledSites: Record<string, boolean>;
  autoSync: boolean;
}

export const DEFAULT_SETTINGS: ExtensionSettings = {
  syncIntervalMs: __DEFAULT_SYNC_INTERVAL_MS__,
  enabledSites: {},
  autoSync: true,
};

export const STORAGE_KEYS = {
  AUTH: 'auth',
  UNSYNCED_EVENTS: 'unsyncedEvents',
  PARSER_CACHE: 'parserCache',
  READING_SESSIONS: 'readingSessions',
  READING_HISTORY: 'readingHistory',
  SYNC_STATUS: 'syncStatus',
  SETTINGS: 'settings',
} as const;
