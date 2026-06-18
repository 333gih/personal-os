import { useCallback, useEffect, useState } from 'react';
import browser from 'webextension-polyfill';
import type { SyncStatus } from '../types/reading';
import { MESSAGE_TYPES } from '../shared/messages';

export function useSyncStatus() {
  const [status, setStatus] = useState<SyncStatus>({
    state: 'idle',
    lastSyncAt: null,
    pendingCount: 0,
  });

  const refresh = useCallback(async () => {
    const response = await browser.runtime.sendMessage({
      type: MESSAGE_TYPES.GET_SYNC_STATUS,
    });
    if (response?.success) {
      setStatus(response.data as SyncStatus);
    }
  }, []);

  useEffect(() => {
    void refresh();
    const interval = setInterval(refresh, 3000);
    return () => clearInterval(interval);
  }, [refresh]);

  const syncNow = async () => {
    setStatus((s) => ({ ...s, state: 'syncing' }));
    const response = await browser.runtime.sendMessage({ type: MESSAGE_TYPES.SYNC_NOW });
    await refresh();
    return response?.data;
  };

  return { status, refresh, syncNow };
}
