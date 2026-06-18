import { useCallback, useEffect, useState } from 'react';
import browser from 'webextension-polyfill';
import type { ReadingSession } from '../types/reading';
import { MESSAGE_TYPES } from '../shared/messages';

export function useReadingState() {
  const [session, setSession] = useState<ReadingSession | null>(null);
  const [loading, setLoading] = useState(true);

  const refresh = useCallback(async () => {
    const response = await browser.runtime.sendMessage({
      type: MESSAGE_TYPES.GET_CURRENT_READING,
    });
    if (response?.success) {
      setSession(response.data as ReadingSession | null);
    }
    setLoading(false);
  }, []);

  useEffect(() => {
    void refresh();
    const interval = setInterval(refresh, 5000);
    return () => clearInterval(interval);
  }, [refresh]);

  return { session, loading, refresh };
}
