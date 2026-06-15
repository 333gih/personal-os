import "server-only";

import { authUpstreamBase } from "./auth-upstream-base";

const DEFAULT_TIMEOUT_MS = 15_000;

export type BackendResult<T> =
  | { ok: true; status: number; data: T }
  | { ok: false; status: number; text: string; json?: unknown };

function joinUrl(base: string, path: string): string {
  return `${base.replace(/\/+$/, "")}${path.startsWith("/") ? path : `/${path}`}`;
}

export type AuthBackendInit = RequestInit & {
  accessToken?: string;
  timeoutMs?: number;
};

export async function callAuthBackend<T>(
  path: string,
  init: AuthBackendInit = {},
): Promise<BackendResult<T>> {
  const normalized = path.startsWith("/") ? path : `/${path}`;
  const url = joinUrl(authUpstreamBase(), normalized);

  const controller = new AbortController();
  const timeoutMs = init.timeoutMs ?? DEFAULT_TIMEOUT_MS;
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  const { accessToken, timeoutMs: _tm, ...reqInit } = init;
  const headers = new Headers(reqInit.headers);
  if (!headers.has("Content-Type") && reqInit.body) {
    headers.set("Content-Type", "application/json");
  }
  if (accessToken) {
    headers.set("Authorization", `Bearer ${accessToken}`);
  }

  try {
    const res = await fetch(url, {
      ...reqInit,
      headers,
      signal: controller.signal,
      cache: "no-store",
    });

    const status = res.status;
    if (status === 204 || status === 202) {
      return { ok: true, status, data: undefined as T };
    }

    const text = await res.text();
    let json: unknown;
    try {
      json = text ? JSON.parse(text) : undefined;
    } catch {
      json = undefined;
    }

    if (!res.ok) {
      console.error("[auth-bff] upstream error", { method: reqInit.method ?? "GET", url, status, json });
      return { ok: false, status, text, json };
    }

    return { ok: true, status, data: (json ?? null) as T };
  } catch (e) {
    const message = e instanceof Error ? e.message : "Unknown error";
    console.error("[auth-bff] fetch error", { method: reqInit.method ?? "GET", url, message });
    return { ok: false, status: 0, text: message };
  } finally {
    clearTimeout(timeout);
  }
}

export async function postJson<T>(
  relativePath: string,
  body?: unknown,
  opts: { accessToken?: string; timeoutMs?: number } = {},
): Promise<BackendResult<T>> {
  const init: AuthBackendInit = {
    method: "POST",
    accessToken: opts.accessToken,
    timeoutMs: opts.timeoutMs,
  };
  if (body !== undefined) {
    init.body = JSON.stringify(body);
  }
  return callAuthBackend<T>(relativePath, init);
}
