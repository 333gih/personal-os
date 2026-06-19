import { afterEach, describe, expect, it, vi } from 'vitest';
import { ApiClient } from './api-client';

describe('ApiClient auth headers', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('sends Authorization Bearer when getAccessToken returns a token', async () => {
    const fetchMock = vi.fn(async (_input: RequestInfo, init?: RequestInit) => {
      const headers = new Headers(init?.headers);
      expect(headers.get('Authorization')).toBe('Bearer test-access-token');
      return new Response(JSON.stringify({ ok: true }), { status: 200 });
    });
    vi.stubGlobal('fetch', fetchMock);

    const client = new ApiClient({
      config: {
        baseUrl: 'https://api-personal-os.fashandcurious.com/api/v1',
        timeout: 5000,
        endpoints: {
          readingProgress: '/reading-progress',
          readingProgressCurrent: '/reading-progress/current',
        },
      },
      getAccessToken: async () => 'test-access-token',
      requireAuth: true,
    });

    await client.post('/reading-progress', { story_id: 'x', story_title: 'Y', progress: {} });

    expect(fetchMock).toHaveBeenCalledOnce();
  });

  it('does not call fetch when requireAuth and token is missing', async () => {
    const fetchMock = vi.fn();
    vi.stubGlobal('fetch', fetchMock);

    const client = new ApiClient({
      config: {
        baseUrl: 'https://api-personal-os.fashandcurious.com/api/v1',
        timeout: 5000,
        endpoints: {
          readingProgress: '/reading-progress',
          readingProgressCurrent: '/reading-progress/current',
        },
      },
      getAccessToken: async () => null,
      requireAuth: true,
    });

    await expect(client.get('/reading-progress/current')).rejects.toMatchObject({
      name: 'ApiError',
      status: 401,
    });
    expect(fetchMock).not.toHaveBeenCalled();
  });
});
