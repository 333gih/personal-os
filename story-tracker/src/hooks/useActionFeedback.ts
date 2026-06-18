import { useCallback, useRef, useState } from 'react';

export type ActionFeedbackState = 'idle' | 'loading' | 'success' | 'error';

export function useActionFeedback() {
  const [state, setState] = useState<ActionFeedbackState>('idle');
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
    try {
      await action();
      setState('success');
      timerRef.current = setTimeout(() => setState('idle'), 2000);
    } catch {
      setState('error');
      timerRef.current = setTimeout(() => setState('idle'), 2500);
    }
  }, []);

  return { state, run, isLoading: state === 'loading', isSuccess: state === 'success', isError: state === 'error' };
}
