import { describe, expect, it, vi, beforeEach } from 'vitest';
import { GUEST_MAX_STORIES } from '../shared/constants';

vi.mock('../auth/auth-service', () => ({
  authService: {
    isAuthenticated: vi.fn(),
  },
}));

vi.mock('../storage/storage-service', () => ({
  storageService: {
    get: vi.fn(),
  },
}));

import { authService } from '../auth/auth-service';
import { storageService } from '../storage/storage-service';
import { canSaveGuestStory, isGuestMode } from './guest-mode';

describe('guest-mode', () => {
  beforeEach(() => {
    vi.mocked(authService.isAuthenticated).mockReset();
    vi.mocked(storageService.get).mockReset();
  });

  it('detects guest when not authenticated', async () => {
    vi.mocked(authService.isAuthenticated).mockResolvedValue(false);
    await expect(isGuestMode()).resolves.toBe(true);
  });

  it('allows saving when under guest story limit', async () => {
    vi.mocked(authService.isAuthenticated).mockResolvedValue(false);
    vi.mocked(storageService.get).mockResolvedValue({
      a: {},
      b: {},
    });
    await expect(canSaveGuestStory('new-story')).resolves.toBe(true);
  });

  it('blocks new story when guest limit reached', async () => {
    vi.mocked(authService.isAuthenticated).mockResolvedValue(false);
    vi.mocked(storageService.get).mockResolvedValue(
      Object.fromEntries(Array.from({ length: GUEST_MAX_STORIES }, (_, i) => [`s${i}`, {}])),
    );
    await expect(canSaveGuestStory('brand-new')).resolves.toBe(false);
  });

  it('still allows updating an existing guest story at limit', async () => {
    vi.mocked(authService.isAuthenticated).mockResolvedValue(false);
    vi.mocked(storageService.get).mockResolvedValue({
      s1: {},
      s2: {},
      s3: {},
      s4: {},
      s5: {},
    });
    await expect(canSaveGuestStory('s3')).resolves.toBe(true);
  });

  it('allows unlimited saves when signed in', async () => {
    vi.mocked(authService.isAuthenticated).mockResolvedValue(true);
    await expect(canSaveGuestStory('any-story')).resolves.toBe(true);
    expect(storageService.get).not.toHaveBeenCalled();
  });
});
