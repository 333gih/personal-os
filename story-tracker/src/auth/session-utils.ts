import type { AuthState } from './types';
import { decodeJwtPayload, isAccessTokenExpired } from './jwt';
import { ACCESS_REFRESH_LEAD_MS } from './constants';

const REFRESH_SKEW_MS = 60_000;

export function isRefreshTokenValid(auth: AuthState, now = Date.now()): boolean {
  return now < auth.tokens.refreshExpiresAt - REFRESH_SKEW_MS;
}

export function shouldRefreshAccessToken(
  auth: AuthState,
  leadMs = ACCESS_REFRESH_LEAD_MS,
  now = Date.now(),
): boolean {
  return now >= auth.tokens.expiresAt - leadMs;
}

export function canUseStoredAccessToken(auth: AuthState, now = Date.now()): boolean {
  if (now >= auth.tokens.expiresAt) return false;
  const payload = decodeJwtPayload(auth.tokens.accessToken);
  if (!payload || typeof payload.exp !== 'number') {
    return true;
  }
  return !isAccessTokenExpired(auth.tokens.accessToken, 15);
}
