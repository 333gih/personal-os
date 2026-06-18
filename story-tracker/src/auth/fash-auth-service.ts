import type {
  FashLoginRequest,
  FashLogoutRequest,
  FashRegisterRequest,
  FashTokenResponse,
} from './fash-types';
import { getApplicationId, joinAuthUrl } from './auth-api-config';
import type { AuthMode } from './types';
import { lockedRefresh } from './locked-refresh';

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

export class FashAuthService {
  async login(email: string, password: string, mode: AuthMode): Promise<FashTokenResponse> {
    const body: FashLoginRequest = {
      email: email.trim(),
      password,
      application_id: getApplicationId(mode),
    };
    return postAuthJson<FashTokenResponse>('/api/v1/auth/login', body);
  }

  async register(
    email: string,
    password: string,
    name: string,
    mode: AuthMode,
  ): Promise<FashTokenResponse> {
    const body: FashRegisterRequest = {
      email: email.trim(),
      password,
      name: name.trim(),
      application_id: getApplicationId(mode),
    };
    return postAuthJson<FashTokenResponse>('/api/v1/auth/register', body);
  }

  async refresh(refreshToken: string, mode: AuthMode): Promise<FashTokenResponse> {
    return lockedRefresh(refreshToken, mode);
  }

  async logout(refreshToken: string, mode: AuthMode): Promise<void> {
    const body: FashLogoutRequest = {
      refresh_token: refreshToken,
      application_id: getApplicationId(mode),
    };
    try {
      await postAuthJson<void>('/api/v1/auth/logout', body);
    } catch {
      // Best-effort logout upstream; local session is always cleared.
    }
  }
}

export const fashAuthService = new FashAuthService();
