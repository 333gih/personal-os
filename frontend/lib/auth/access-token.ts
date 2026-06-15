"use client";

import { isAccessTokenExpired } from "./jwt";

let cachedToken: string | null = null;
let inflight: Promise<string | null> | null = null;

export function clearAccessTokenCache() {
  cachedToken = null;
  inflight = null;
}

export async function getAccessToken(forceRefresh = false): Promise<string | null> {
  if (!forceRefresh && cachedToken && !isAccessTokenExpired(cachedToken)) {
    return cachedToken;
  }

  if (inflight) return inflight;

  inflight = fetch("/api/auth/token", {
    credentials: "same-origin",
    headers: { Accept: "application/json" },
    cache: "no-store",
  })
    .then(async (res) => {
      if (!res.ok) {
        cachedToken = null;
        return null;
      }
      const data = (await res.json()) as { access_token?: string };
      const token = data.access_token?.trim() || null;
      cachedToken = token;
      return token;
    })
    .catch(() => {
      cachedToken = null;
      return null;
    })
    .finally(() => {
      inflight = null;
    });

  return inflight;
}

export async function authHeaders(
  initHeaders?: HeadersInit,
  forceToken = false,
): Promise<Headers> {
  const headers = new Headers(initHeaders);
  if (!headers.has("Authorization")) {
    const token = await getAccessToken(forceToken);
    if (token) {
      headers.set("Authorization", `Bearer ${token}`);
    }
  }
  if (!headers.has("Accept")) {
    headers.set("Accept", "application/json");
  }
  return headers;
}
