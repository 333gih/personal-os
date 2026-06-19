import { useCallback, useRef, useState } from 'react';

export type ActionFeedbackState = 'idle' | 'loading' | 'success' | 'error';

export function useActionFeedback() {
  const [state, setState] = useState<ActionFeedbackState>('idle');
  const [lastError, setLastError] = useState<string | null>(null);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const clearTimer = () => {
    if (timerRef.current) {
      clearTimeout(timerRef.current);
      timerRef.current = null;
    }
  };

  const run = useCallback(async (action: () => Promise<void>) => {
    clearTimer();
    setState('loading');
    setLastError(null);
    try {
      await action();
      setState('success');
      timerRef.current = setTimeout(() => setState('idle'), 2000);
    } catch (error) {
      setLastError(error instanceof Error ? error.message : 'Action failed');
      setState('error');
      timerRef.current = setTimeout(() => setState('idle'), 2500);
    }
  }, []);

  return {
    state,
    run,
    lastError,
    isLoading: state === 'loading',
    isSuccess: state === 'success',
    isError: state === 'error',
  };
}
