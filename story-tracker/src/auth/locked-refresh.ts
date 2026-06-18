import type { FashTokenResponse, FashRefreshRequest } from './fash-types';
import { joinAuthUrl, getApplicationId } from './auth-api-config';
import type { AuthMode } from './types';

const locks = new Map<string, Promise<FashTokenResponse>>();

async function postAuthJson<T>(path: string, body: unknown): Promise<T> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), __API_TIMEOUT__);

  try {
    const response = await fetch(joinAuthUrl(path), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify(body),
      signal: controller.signal,
    });

    const text = await response.text();
    let json: unknown;
    try {
      json = text ? JSON.parse(text) : undefined;
    } catch {
      json = undefined;
    }

    if (!response.ok) {
      const err = json as { message?: string; error?: string; detail?: string } | undefined;
      const message = err?.message ?? err?.error ?? err?.detail ?? `Auth request failed (${response.status})`;
      throw new Error(message);
    }

    return json as T;
  } finally {
    clearTimeout(timeout);
  }
}

export async function lockedRefresh(
  refreshToken: string,
  mode: AuthMode,
): Promise<FashTokenResponse> {
  const cacheKey = `${mode}:${refreshToken}`;
  const cached = locks.get(cacheKey);
  if (cached) return cached;

  const body: FashRefreshRequest = {
    refresh_token: refreshToken,
    application_id: getApplicationId(mode),
  };

  const started = postAuthJson<FashTokenResponse>('/api/v1/auth/refresh', body).finally(() => {
    locks.delete(cacheKey);
  });

  locks.set(cacheKey, started);
  return started;
}
