import { GUEST_MAX_STORIES } from '../shared/constants';
import { authService } from '../auth/auth-service';
import { storageService } from '../storage/storage-service';

export type GuestStatus = {
  isGuest: boolean;
  storyCount: number;
  maxStories: number;
  atLimit: boolean;
};

export const GUEST_LIMIT_CODE = 'GUEST_LIMIT';

export const GUEST_LIMIT_MESSAGE =
  `Guest mode stores up to ${GUEST_MAX_STORIES} stories on this device only. ` +
  'Remove a story from Recent stories below (×), or clear all in Settings, then save again. ' +
  'Sign in to Personal OS for unlimited cloud sync across devices.';

export const GUEST_UPSELL_TITLE = 'Sign in for cloud sync';
export const GUEST_UPSELL_BODY =
  'Without signing in, progress stays on this browser only (max 5 stories). ' +
  'Sign in to sync with Personal OS, use multiple devices, and see reading history in the web app.';

export async function isGuestMode(): Promise<boolean> {
  return !(await authService.isAuthenticated());
}

export async function countGuestStories(): Promise<number> {
  const sessions = await storageService.get('readingSessions');
  return Object.keys(sessions).length;
}

export async function getGuestStatus(): Promise<GuestStatus> {
  const isGuest = !(await authService.isAuthenticated());
  const storyCount = isGuest ? await countGuestStories() : 0;
  return {
    isGuest,
    storyCount,
    maxStories: GUEST_MAX_STORIES,
    atLimit: isGuest && storyCount >= GUEST_MAX_STORIES,
  };
}

export async function canSaveGuestStory(storyId: string): Promise<boolean> {
  if (!(await isGuestMode())) return true;

  const sessions = await storageService.get('readingSessions');
  if (storyId in sessions) return true;
  return Object.keys(sessions).length < GUEST_MAX_STORIES;
}
