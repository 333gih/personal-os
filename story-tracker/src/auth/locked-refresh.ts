import type { FashTokenResponse, FashRefreshRequest } from './fash-types';
import { getApplicationId } from './auth-api-config';
import { postAuthJson } from './auth-http';
import type { AuthMode } from './types';

const locks = new Map<string, Promise<FashTokenResponse>>();

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
