import { describe, expect, it } from 'vitest';
import {
  hasReadingPathKeywords,
  hasReadingUrlSignals,
  isLikelyListingPage,
} from './url-detector';

describe('url-detector', () => {
  it('detects truyen in path', () => {
    expect(hasReadingPathKeywords('https://vietnamthuquan.eu/truyen/truyen.aspx?tid=abc')).toBe(
      true,
    );
  });

  it('detects thuquan host on reader path', () => {
    expect(
      hasReadingUrlSignals(
        'https://vietnamthuquan.eu/truyen/truyen.aspx?tid=abc',
      ),
    ).toBe(true);
  });

  it('excludes listing pages', () => {
    expect(isLikelyListingPage('https://truyenfull.today/')).toBe(true);
    expect(hasReadingUrlSignals('https://truyenfull.today/')).toBe(false);
  });
});
