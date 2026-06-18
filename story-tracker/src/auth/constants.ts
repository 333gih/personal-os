/** Refresh access token this many ms before stored expiry. */
export const ACCESS_REFRESH_LEAD_MS = 5 * 60 * 1000;

/** Background alarm — proactive token refresh while extension is installed. */
export const AUTH_REFRESH_ALARM = 'story-tracker-auth-refresh';

/** Minimum interval between scheduled refresh attempts. */
export const AUTH_REFRESH_PERIOD_MINUTES = 4;

/** Popup/tab waits this long for user to finish Personal OS sign-in. */
export const WEB_AUTH_UI_TIMEOUT_MS = 15 * 60 * 1000;

/** Handoff nonce stays valid after UI timeout (SSO redirects can be slow). */
export const WEB_AUTH_HANDOFF_GRACE_MS = 25 * 60 * 1000;
