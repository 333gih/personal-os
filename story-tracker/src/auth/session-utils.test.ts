import { describe, expect, it } from 'vitest';
import type { AuthState } from './types';
import {
  canUseStoredAccessToken,
  isRefreshTokenValid,
  shouldRefreshAccessToken,
} from './session-utils';

function authState(overrides: Partial<AuthState['tokens']> = {}): AuthState {
  const now = Date.now();
  return {
    mode: 'commercial',
    applicationId: 'web',
    tokens: {
      accessToken: 'token',
      refreshToken: 'refresh',
      expiresAt: now + 3600_000,
      refreshExpiresAt: now + 604800_000,
      ...overrides,
    },
    user: { id: '1', email: 'a@b.com', isAdmin: false },
  };
}

describe('session-utils', () => {
  it('detects refresh token expiry', () => {
    const expired = authState({ refreshExpiresAt: Date.now() - 1000 });
    expect(isRefreshTokenValid(expired)).toBe(false);
  });

  it('refreshes access token before expiry window', () => {
    const soon = authState({ expiresAt: Date.now() + 2 * 60_000 });
    expect(shouldRefreshAccessToken(soon)).toBe(true);
  });

  it('keeps valid access token when not near expiry', () => {
    const fresh = authState({ expiresAt: Date.now() + 60 * 60_000 });
    expect(shouldRefreshAccessToken(fresh)).toBe(false);
    expect(canUseStoredAccessToken(fresh)).toBe(true);
  });
});
