import { useCallback, useEffect, useState } from 'react';
import browser from 'webextension-polyfill';
import { GUEST_MAX_STORIES } from '../shared/constants';
import type { GuestStatus } from '../guest/guest-mode';
import { MESSAGE_TYPES } from '../shared/messages';
import { STORAGE_KEYS } from '../types/storage';

const DEFAULT_GUEST_STATUS: GuestStatus = {
  isGuest: false,
  storyCount: 0,
  maxStories: GUEST_MAX_STORIES,
  atLimit: false,
};

/** Story counts for guest limit UI — `isGuest` in popup must come from `useAuth`, not this hook. */
export function useGuestStatus(enabled: boolean) {
  const [guestStatus, setGuestStatus] = useState<GuestStatus>(DEFAULT_GUEST_STATUS);

  const refresh = useCallback(async () => {
    if (!enabled) {
      setGuestStatus(DEFAULT_GUEST_STATUS);
      return;
    }
    const response = await browser.runtime.sendMessage({
      type: MESSAGE_TYPES.GET_GUEST_STATUS,
    });
    if (response?.success) {
      setGuestStatus(response.data as GuestStatus);
    }
  }, [enabled]);

  useEffect(() => {
    void refresh();
    if (!enabled) return;

    const interval = setInterval(() => void refresh(), 5000);
    const onStorageChanged = (
      changes: Record<string, browser.Storage.StorageChange>,
      area: string,
    ) => {
      if (area !== 'local') return;
      if (changes[STORAGE_KEYS.READING_SESSIONS] || changes[STORAGE_KEYS.READING_HISTORY]) {
        void refresh();
      }
    };

    browser.storage.onChanged.addListener(onStorageChanged);
    return () => {
      clearInterval(interval);
      browser.storage.onChanged.removeListener(onStorageChanged);
    };
  }, [enabled, refresh]);

  return { guestStatus, refresh };
}
