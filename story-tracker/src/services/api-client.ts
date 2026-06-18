import type { ApiConfig, ApiErrorBody } from '../types/api';
import { logger } from '../utils/logger';
import { MAX_RETRY_ATTEMPTS, RETRY_BASE_DELAY_MS } from '../shared/constants';

export type TokenProvider = () => Promise<string | null>;
export type RequestInterceptor = (init: RequestInit) => Promise<RequestInit> | RequestInit;
export type OnUnauthorized = () => Promise<boolean>;

export interface ApiClientOptions {
  config: ApiConfig;
  getAccessToken?: TokenProvider;
  onUnauthorized?: OnUnauthorized;
  interceptors?: RequestInterceptor[];
  requireAuth?: boolean;
}

export class ApiError extends Error {
  constructor(
    message: string,
    public readonly status: number,
    public readonly body?: ApiErrorBody,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

export class ApiClient {
  private readonly config: ApiConfig;
  private readonly getAccessToken?: TokenProvider;
  private readonly onUnauthorized?: OnUnauthorized;
  private readonly interceptors: RequestInterceptor[];
  private readonly requireAuth: boolean;

  constructor(options: ApiClientOptions) {
    this.config = options.config;
    this.getAccessToken = options.getAccessToken;
    this.onUnauthorized = options.onUnauthorized;
    this.interceptors = options.interceptors ?? [];
    this.requireAuth = options.requireAuth ?? false;
  }

  async request<T>(
    path: string,
    init: RequestInit = {},
    options?: { skipAuth?: boolean; retries?: number },
  ): Promise<T> {
    const retries = options?.retries ?? MAX_RETRY_ATTEMPTS;
    let lastError: unknown;
    let unauthorizedRetried = false;

    for (let attempt = 0; attempt <= retries; attempt++) {
      try {
        return await this.executeRequest<T>(path, init, options?.skipAuth, unauthorizedRetried);
      } catch (error) {
        if (
          error instanceof ApiError &&
          error.status === 401 &&
          !options?.skipAuth &&
          !unauthorizedRetried &&
          this.onUnauthorized
        ) {
          const refreshed = await this.onUnauthorized();
          if (refreshed) {
            unauthorizedRetried = true;
            continue;
          }
        }

        lastError = error;
        if (!this.shouldRetry(error, attempt, retries)) throw error;
        const delay = RETRY_BASE_DELAY_MS * Math.pow(2, attempt);
        logger.warn(`Request failed, retrying in ${delay}ms (attempt ${attempt + 1})`);
        await sleep(delay);
      }
    }

    throw lastError;
  }

  get<T>(path: string, init?: RequestInit, options?: { skipAuth?: boolean }): Promise<T> {
    return this.request<T>(path, { ...init, method: 'GET' }, options);
  }

  post<T>(
    path: string,
    body?: unknown,
    init?: RequestInit,
    options?: { skipAuth?: boolean },
  ): Promise<T> {
    return this.request<T>(
      path,
      {
        ...init,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
          ...(init?.headers ?? {}),
        },
        body: body !== undefined ? JSON.stringify(body) : undefined,
      },
      options,
    );
  }

  private async executeRequest<T>(
    path: string,
    init: RequestInit,
    skipAuth?: boolean,
    _unauthorizedRetried?: boolean,
  ): Promise<T> {
    const url = this.resolveUrl(path);
    let requestInit: RequestInit = {
      ...init,
      headers: {
        Accept: 'application/json',
        ...(init.headers ?? {}),
      },
    };

    if (!skipAuth && this.getAccessToken) {
      const token = await this.getAccessToken();
      if (!token && this.requireAuth) {
        throw new ApiError('Not authenticated. Please sign in.', 401);
      }
      if (token) {
        requestInit.headers = {
          ...requestInit.headers,
          Authorization: `Bearer ${token}`,
        };
      }
    }

    for (const interceptor of this.interceptors) {
      requestInit = await interceptor(requestInit);
    }

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), this.config.timeout);

    try {
      const response = await fetch(url, {
        ...requestInit,
        signal: controller.signal,
      });

      if (!response.ok) {
        let body: ApiErrorBody | undefined;
        try {
          body = (await response.json()) as ApiErrorBody;
        } catch {
          /* empty body */
        }
        const message =
          body?.message ?? body?.error ?? body?.detail ??
          `Request failed with status ${response.status}`;
        throw new ApiError(message, response.status, body);
      }

      if (response.status === 204) return undefined as T;
      const text = await response.text();
      if (!text) return undefined as T;
      return JSON.parse(text) as T;
    } finally {
      clearTimeout(timeout);
    }
  }

  private resolveUrl(path: string): string {
    if (path.startsWith('http')) return path;
    const base = this.config.baseUrl.replace(/\/$/, '');
    const normalized = path.startsWith('/') ? path : `/${path}`;
    return `${base}${normalized}`;
  }

  private shouldRetry(error: unknown, attempt: number, maxRetries: number): boolean {
    if (attempt >= maxRetries) return false;
    if (error instanceof ApiError) {
      if (error.status === 401 || error.status === 403) return false;
      if (error.status >= 400 && error.status < 500) return false;
    }
    if (error instanceof DOMException && error.name === 'AbortError') return true;
    return true;
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
