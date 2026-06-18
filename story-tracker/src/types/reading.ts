export interface ReadingProgress {
  percentage: number;
  scrollY: number;
  readingTimeSeconds: number;
}

export interface ReadingInfo {
  storyId: string;
  storyTitle: string;
  chapterId?: string;
  chapterTitle?: string;
  currentUrl: string;
  progress: ReadingProgress;
  metadata?: Record<string, unknown>;
}

export interface ReadingSession {
  id: string;
  readingInfo: ReadingInfo;
  startedAt: number;
  lastUpdatedAt: number;
  siteId: string;
}

export interface ReadingHistoryEntry {
  storyId: string;
  storyTitle: string;
  chapterId?: string;
  chapterTitle?: string;
  currentUrl: string;
  progress: ReadingProgress;
  lastReadAt: number;
  siteId: string;
}

export interface SyncStatus {
  state: 'idle' | 'syncing' | 'error' | 'offline';
  lastSyncAt: number | null;
  pendingCount: number;
  lastError?: string;
  /** Browser connectivity; enriched at read time in the background script. */
  online?: boolean;
}

export interface SyncNowResult {
  synced: number;
  failed: number;
  pushedLatest: boolean;
  error?: string;
}
