export const COOKIE_ACCESS = "personal_os_at";
export const COOKIE_REFRESH = "personal_os_rt";
export const COOKIE_AUTH_PERSIST = "personal_os_ps";

export const API_V1 = "/api/v1";

/** BFF attaches on portal-session 401 so client knows to refresh cookies. */
export const PORTAL_COOKIE_REFRESH_401_HEADER = "x-personal-os-portal-cookie-retry";
export const PORTAL_COOKIE_REFRESH_401_VALUE = "1";
