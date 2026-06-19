import { getBuiltinProfiles } from '../config/site-profile-builtin';

export const SYNC_DEBOUNCE_MS = 2000;
export const SCROLL_THROTTLE_MS = 500;
export const MAX_HISTORY_ENTRIES = 50;
/** Max distinct stories saved locally without signing in. */
export const GUEST_MAX_STORIES = 5;
export const MAX_RETRY_ATTEMPTS = 5;
export const RETRY_BASE_DELAY_MS = 1000;
export const TOKEN_REFRESH_BUFFER_MS = 60_000;
export const OFFLINE_QUEUE_MAX_SIZE = 500;

export const SUPPORTED_SITES = [
  ...getBuiltinProfiles().map((profile) => ({
    id: profile.id,
    label: profile.label,
    pattern: profile.urlRules.hostPatterns?.[0] ?? '*',
  })),
  { id: 'generic', label: 'Generic (fallback)', pattern: '*' },
] as const;
