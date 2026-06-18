import { describe, expect, it, vi, beforeEach } from 'vitest';

vi.mock('webextension-polyfill', () => ({
  default: {
    storage: {
      session: {
        set: vi.fn().mockResolvedValue(undefined),
        get: vi.fn().mockResolvedValue({}),
        remove: vi.fn().mockResolvedValue(undefined),
      },
      local: {
        set: vi.fn().mockResolvedValue(undefined),
        get: vi.fn().mockResolvedValue({}),
        remove: vi.fn().mockResolvedValue(undefined),
      },
    },
    scripting: {
      executeScript: vi.fn().mockResolvedValue([]),
    },
    tabs: {
      create: vi.fn(),
      remove: vi.fn().mockResolvedValue(undefined),
      onRemoved: {
        addListener: vi.fn(),
        removeListener: vi.fn(),
      },
      onUpdated: {
        addListener: vi.fn(),
        removeListener: vi.fn(),
      },
    },
  },
}));

vi.mock('./auth-service', () => ({
  authService: {
    completeWebHandoff: vi.fn(),
  },
}));

vi.mock('../utils/logger', () => ({
  logger: { warn: vi.fn(), info: vi.fn(), error: vi.fn() },
}));

import browser from 'webextension-polyfill';
import { authService } from './auth-service';
import { processWebAuthHandoff } from './web-auth';

const handoffPayload = {
  access_token: 'access',
  refresh_token: 'refresh',
  token_type: 'bearer' as const,
  expires_in: 3600,
  refresh_expires_in: 604800,
  mode: 'commercial' as const,
  application_id: 'web',
  nonce: 'test-nonce',
};

describe('processWebAuthHandoff', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('accepts handoff when session nonce matches after background restart', async () => {
    vi.mocked(browser.storage.session.get).mockResolvedValue({
      pendingWebAuthNonce: 'test-nonce',
      pendingWebAuthTabId: 42,
      pendingWebAuthAt: Date.now(),
    });
    vi.mocked(authService.completeWebHandoff).mockResolvedValue({
      mode: 'commercial',
      applicationId: 'web',
      tokens: {
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresAt: Date.now() + 3600_000,
        refreshExpiresAt: Date.now() + 604800_000,
      },
      user: { id: '1', email: 'a@b.com', isAdmin: false },
    });

    const result = await processWebAuthHandoff(handoffPayload);

    expect(result.success).toBe(true);
    expect(authService.completeWebHandoff).toHaveBeenCalledWith(handoffPayload);
    expect(browser.tabs.remove).toHaveBeenCalledWith(42);
  });

  it('rejects handoff when nonce does not match pending session', async () => {
    vi.mocked(browser.storage.session.get).mockResolvedValue({
      pendingWebAuthNonce: 'other-nonce',
      pendingWebAuthAt: Date.now(),
    });

    const result = await processWebAuthHandoff(handoffPayload);

    expect(result.success).toBe(false);
    expect(authService.completeWebHandoff).not.toHaveBeenCalled();
  });
});
