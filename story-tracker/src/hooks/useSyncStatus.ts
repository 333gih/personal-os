import { useCallback, useEffect, useState } from 'react';
import browser from 'webextension-polyfill';
import type { SyncNowResult, SyncStatus } from '../types/reading';
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

  const syncNow = async (): Promise<SyncNowResult> => {
    setStatus((s) => ({ ...s, state: 'syncing' }));
    const response = await browser.runtime.sendMessage({ type: MESSAGE_TYPES.SYNC_NOW });
    await refresh();

    if (!response?.success) {
      throw new Error(response?.error ?? 'Sync failed');
    }

    const result = response.data as SyncNowResult;
    if (result.failed > 0 && result.synced === 0) {
      throw new Error(result.error ?? 'Sync failed. Check login or API connection.');
    }

    return result;
  };

  return { status, refresh, syncNow };
}
