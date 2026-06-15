import "server-only";

import { cookies } from "next/headers";

import { COOKIE_ACCESS, COOKIE_AUTH_PERSIST, COOKIE_REFRESH } from "./constants";
import { getServerAuthEnv } from "./server-env";
import type { TokenResponse } from "./types";

export type CookieSetter = {
  set: (
    name: string,
    value: string,
    options?: {
      httpOnly?: boolean;
      secure?: boolean;
      sameSite?: "lax" | "strict" | "none";
      path?: string;
      maxAge?: number;
    },
  ) => void;
};

type CookieReader = {
  get: (name: string) => { value: string } | undefined;
};

function sessionCookieOpts(secure: boolean) {
  return {
    httpOnly: true as const,
    secure,
    sameSite: "lax" as const,
    path: "/",
  };
}

function persistentCookieOpts(maxAge: number, secure: boolean) {
  return {
    ...sessionCookieOpts(secure),
    maxAge,
  };
}

export function readAuthPersistMarker(store: CookieReader): boolean {
  return store.get(COOKIE_AUTH_PERSIST)?.value === "1";
}

export function applyTokenCookies(
  store: CookieSetter,
  tokens: TokenResponse,
  persistent: boolean,
  options?: { secure?: boolean },
): void {
  const secure = options?.secure ?? getServerAuthEnv().cookieSecure;
  const accessMax = Math.max(60, tokens.expires_in);
  const refreshMax = Math.max(300, tokens.refresh_expires_in);

  if (persistent) {
    store.set(COOKIE_ACCESS, tokens.access_token, persistentCookieOpts(accessMax, secure));
    store.set(COOKIE_REFRESH, tokens.refresh_token, persistentCookieOpts(refreshMax, secure));
    store.set(COOKIE_AUTH_PERSIST, "1", persistentCookieOpts(refreshMax, secure));
  } else {
    store.set(COOKIE_ACCESS, tokens.access_token, sessionCookieOpts(secure));
    store.set(COOKIE_REFRESH, tokens.refresh_token, sessionCookieOpts(secure));
    store.set(COOKIE_AUTH_PERSIST, "", { ...sessionCookieOpts(secure), maxAge: 0 });
  }
}

export function clearTokenCookies(store: CookieSetter, options?: { secure?: boolean }): void {
  const secure = options?.secure ?? getServerAuthEnv().cookieSecure;
  const expired = { ...persistentCookieOpts(0, secure), maxAge: 0 };
  store.set(COOKIE_ACCESS, "", expired);
  store.set(COOKIE_REFRESH, "", expired);
  store.set(COOKIE_AUTH_PERSIST, "", expired);
}

export async function readTokensFromCookies(): Promise<{
  access: string | undefined;
  refresh: string | undefined;
}> {
  const store = await cookies();
  return {
    access: store.get(COOKIE_ACCESS)?.value,
    refresh: store.get(COOKIE_REFRESH)?.value,
  };
}
