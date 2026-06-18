import { useCallback, useEffect, useState } from 'react';
import browser from 'webextension-polyfill';
import type { AuthState } from '../auth/types';
import { MESSAGE_TYPES } from '../shared/messages';

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

  const startWebAuth = async () => {
    setError(null);
    setLoading(true);
    const response = await browser.runtime.sendMessage({
      type: MESSAGE_TYPES.START_WEB_AUTH,
    });
    setLoading(false);
    if (response?.success) {
      setAuth(response.data as AuthState);
      return true;
    }
    setError(response?.error ?? 'Sign-in failed');
    return false;
  };

  const logout = async () => {
    await browser.runtime.sendMessage({ type: MESSAGE_TYPES.LOGOUT });
    setAuth(null);
  };

  return { auth, loading, error, startWebAuth, logout, refresh };
}
