import { AuthRequestError } from './auth-request-error';
import { joinAuthUrl } from './auth-api-config';

export async function postAuthJson<T>(path: string, body: unknown): Promise<T> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), __API_TIMEOUT__);

  try {
    const response = await fetch(joinAuthUrl(path), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify(body),
      signal: controller.signal,
    });

    const text = await response.text();
    let json: unknown;
    try {
      json = text ? JSON.parse(text) : undefined;
    } catch {
      json = undefined;
    }

    if (!response.ok) {
      const err = json as { message?: string; error?: string; detail?: string } | undefined;
      const message =
        err?.message ?? err?.error ?? err?.detail ?? `Auth request failed (${response.status})`;
      throw new AuthRequestError(message, response.status);
    }

    return json as T;
  } catch (error) {
    if (error instanceof AuthRequestError) throw error;
    if (error instanceof DOMException && error.name === 'AbortError') {
      throw new AuthRequestError('Auth request timed out', 0);
    }
    throw new AuthRequestError(
      error instanceof Error ? error.message : 'Auth request failed',
      0,
    );
  } finally {
    clearTimeout(timeout);
  }
}
