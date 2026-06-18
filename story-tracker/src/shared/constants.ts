export const SYNC_DEBOUNCE_MS = 2000;
export const SCROLL_THROTTLE_MS = 500;
export const MAX_HISTORY_ENTRIES = 50;
export const MAX_RETRY_ATTEMPTS = 5;
export const RETRY_BASE_DELAY_MS = 1000;
export const TOKEN_REFRESH_BUFFER_MS = 60_000;
export const OFFLINE_QUEUE_MAX_SIZE = 500;

export const SUPPORTED_SITES = [
  { id: 'nettruyen', label: 'NetTruyen', pattern: '*://*.nettruyen*.com/*' },
  { id: 'truyenqq', label: 'TruyenQQ', pattern: '*://*.truyenqq*.com/*' },
  { id: 'truyenfull', label: 'TruyenFull', pattern: '*://*.truyenfull.*/*' },
  { id: 'vietnamthuquan', label: 'Vietnam Thu Quan', pattern: '*://*.thuquansach.com/*' },
  { id: 'generic', label: 'Generic (fallback)', pattern: '*' },
] as const;
