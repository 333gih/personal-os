import "server-only";

import { cookies } from "next/headers";

import { applyTokenCookies, clearTokenCookies, readAuthPersistMarker, readTokensFromCookies } from "./cookies";
import { isAccessTokenExpired } from "./jwt";
import { lockedRefresh } from "./locked-refresh";

export type SessionState =
  | { status: "authenticated"; accessToken: string }
  | { status: "unauthenticated" };

export async function ensureSessionAccess(): Promise<SessionState> {
  const { refresh, access } = await readTokensFromCookies();
  if (!refresh) {
    return { status: "unauthenticated" };
  }

  if (access && !isAccessTokenExpired(access)) {
    return { status: "authenticated", accessToken: access };
  }

  const result = await lockedRefresh(refresh);
  if (!result.ok || !result.data) {
    const jar = await cookies();
    clearTokenCookies(jar);
    return { status: "unauthenticated" };
  }

  const jar = await cookies();
  applyTokenCookies(jar, result.data, readAuthPersistMarker(jar));
  return { status: "authenticated", accessToken: result.data.access_token };
}
