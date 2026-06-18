import { describe, it, expect } from 'vitest';
import { debounce, throttle } from './debounce';

describe('debounce', () => {
  it('delays function execution', async () => {
    vi.useFakeTimers();
    let count = 0;
    const fn = debounce(() => { count++; }, 100);

    fn();
    fn();
    fn();
    expect(count).toBe(0);

    vi.advanceTimersByTime(100);
    expect(count).toBe(1);
    vi.useRealTimers();
  });
});

describe('throttle', () => {
  it('limits execution rate', () => {
    vi.useFakeTimers();
    let count = 0;
    const fn = throttle(() => { count++; }, 100);

    fn();
    expect(count).toBe(1);

    fn();
    expect(count).toBe(1);

    vi.advanceTimersByTime(100);
    expect(count).toBe(2);
    vi.useRealTimers();
  });
});
