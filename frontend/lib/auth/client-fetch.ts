"use client";

import {
  PORTAL_COOKIE_REFRESH_401_HEADER,
  PORTAL_COOKIE_REFRESH_401_VALUE,
} from "./constants";
import { authHeaders, clearAccessTokenCache, getAccessToken } from "./access-token";

const REFRESH_PATH = "/api/auth/refresh";
const LOGIN_PATH = "/login";

function portalSuggestsCookieRefresh(res: Response): boolean {
  return res.headers.get(PORTAL_COOKIE_REFRESH_401_HEADER) === PORTAL_COOKIE_REFRESH_401_VALUE;
}

function redirectToLogin() {
  if (typeof window === "undefined") return;
  const next = encodeURIComponent(window.location.pathname);
  window.location.href = `${LOGIN_PATH}?next=${next}`;
}

export async function portalFetch(input: RequestInfo | URL, init?: RequestInit): Promise<Response> {
  const doFetch = async (forceToken = false) => {
    const headers = await authHeaders(init?.headers, forceToken);
    return fetch(input, {
      ...init,
      headers,
      credentials: init?.credentials ?? "same-origin",
    });
  };

  let res = await doFetch();
  if (res.status !== 401) {
    return res;
  }

  if (!portalSuggestsCookieRefresh(res)) {
    return res;
  }

  const refresh = await fetch(REFRESH_PATH, {
    method: "POST",
    credentials: "same-origin",
    headers: { Accept: "application/json" },
  });

  if (!refresh.ok) {
    clearAccessTokenCache();
    redirectToLogin();
    return res;
  }

  clearAccessTokenCache();
  await getAccessToken(true);
  res = await doFetch(true);

  if (res.status === 401 && portalSuggestsCookieRefresh(res)) {
    clearAccessTokenCache();
    redirectToLogin();
  }

  return res;
}
