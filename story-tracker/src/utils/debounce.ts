export function debounce<T extends (...args: Parameters<T>) => void>(
  fn: T,
  delayMs: number,
): (...args: Parameters<T>) => void {
  let timer: ReturnType<typeof setTimeout> | null = null;
  return (...args: Parameters<T>) => {
    if (timer) clearTimeout(timer);
    timer = setTimeout(() => fn(...args), delayMs);
  };
}

export function throttle<T extends (...args: Parameters<T>) => void>(
  fn: T,
  intervalMs: number,
): (...args: Parameters<T>) => void {
  let lastRun = 0;
  let pending: Parameters<T> | null = null;
  let timer: ReturnType<typeof setTimeout> | null = null;

  const run = () => {
    if (!pending) return;
    lastRun = Date.now();
    fn(...pending);
    pending = null;
  };

  return (...args: Parameters<T>) => {
    pending = args;
    const elapsed = Date.now() - lastRun;
    if (elapsed >= intervalMs) {
      if (timer) {
        clearTimeout(timer);
        timer = null;
      }
      run();
    } else if (!timer) {
      timer = setTimeout(() => {
        timer = null;
        run();
      }, intervalMs - elapsed);
    }
  };
}
