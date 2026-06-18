import { useCallback, useEffect, useState } from 'react';
import browser from 'webextension-polyfill';
import type { AuthState } from '../auth/types';
import { MESSAGE_TYPES } from '../shared/messages';
import { STORAGE_KEYS } from '../types/storage';

export function useAuth() {
  const [auth, setAuth] = useState<AuthState | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    const response = await browser.runtime.sendMessage({
      type: MESSAGE_TYPES.GET_AUTH_STATE,
    });
    if (response?.success) {
      setAuth(response.data as AuthState | null);
    }
    setLoading(false);
  }, []);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  useEffect(() => {
    const onStorageChanged = (
      changes: Record<string, browser.Storage.StorageChange>,
      area: string,
    ) => {
      if (area !== 'local' || !changes[STORAGE_KEYS.AUTH]) return;
      setAuth((changes[STORAGE_KEYS.AUTH].newValue as AuthState | null | undefined) ?? null);
      setLoading(false);
      setError(null);
    };

    browser.storage.onChanged.addListener(onStorageChanged);
    return () => {
      browser.storage.onChanged.removeListener(onStorageChanged);
    };
  }, []);

  const startWebAuth = async () => {
    setError(null);
    setLoading(true);
    try {
      const response = await browser.runtime.sendMessage({
        type: MESSAGE_TYPES.START_WEB_AUTH,
      });
      if (response?.success && response.data) {
        setAuth(response.data as AuthState);
        return true;
      }
      if (!response?.success) {
        setError(response?.error ?? 'Sign-in failed');
        return false;
      }
      // Popup may close while the connect tab finishes; refresh picks up stored auth.
      await refresh();
      return Boolean(response?.success);
    } catch (err) {
      // sendMessage rejects when the popup closes before the background responds.
      await refresh();
      const state = await browser.runtime.sendMessage({
        type: MESSAGE_TYPES.GET_AUTH_STATE,
      });
      if (state?.success && state.data) {
        setAuth(state.data as AuthState);
        return true;
      }
      setError(err instanceof Error ? err.message : 'Sign-in failed');
      return false;
    } finally {
      setLoading(false);
    }
  };

  const logout = async () => {
    await browser.runtime.sendMessage({ type: MESSAGE_TYPES.LOGOUT });
    setAuth(null);
  };

  return { auth, loading, error, startWebAuth, logout, refresh };
}
