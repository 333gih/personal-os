import { useCallback, useEffect, useState } from 'react';
import browser from 'webextension-polyfill';
import type { AuthMode, AuthState } from '../auth/types';
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

  const login = async (email: string, password: string, mode: AuthMode) => {
    setError(null);
    setLoading(true);
    const response = await browser.runtime.sendMessage({
      type: MESSAGE_TYPES.LOGIN,
      payload: { email, password, mode },
    });
    setLoading(false);
    if (response?.success) {
      setAuth(response.data as AuthState);
      return true;
    }
    setError(response?.error ?? 'Login failed');
    return false;
  };

  const requestOtp = async (email: string) => {
    setError(null);
    setLoading(true);
    const response = await browser.runtime.sendMessage({
      type: MESSAGE_TYPES.REQUEST_OTP,
      payload: { email, mode: 'commercial' },
    });
    setLoading(false);
    if (response?.success) {
      return response.data as { isNewUser?: boolean };
    }
    setError(response?.error ?? 'Could not send verification code');
    return null;
  };

  const verifyOtp = async (email: string, otp: string) => {
    setError(null);
    setLoading(true);
    const response = await browser.runtime.sendMessage({
      type: MESSAGE_TYPES.VERIFY_OTP,
      payload: { email, otp, mode: 'commercial' },
    });
    setLoading(false);
    if (response?.success) {
      setAuth(response.data as AuthState);
      return true;
    }
    setError(response?.error ?? 'Verification failed');
    return false;
  };

  const logout = async () => {
    await browser.runtime.sendMessage({ type: MESSAGE_TYPES.LOGOUT });
    setAuth(null);
  };

  return { auth, loading, error, login, requestOtp, verifyOtp, logout, refresh };
}
