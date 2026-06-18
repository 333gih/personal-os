import type { AuthMode } from './types';

function stripTrailingSlash(value: string): string {
  return value.replace(/\/+$/, '');
}

function stripTrailingLocaleSegment(url: string): string {
  return stripTrailingSlash(url).replace(/\/(?:vi|en)$/i, '');
}

export function getAuthUpstreamBase(): string {
  const root = stripTrailingLocaleSegment(__AUTH_API_URL__);
  const locale = (__AUTH_LOCALE__ || 'vi').trim();
  return `${root}/${locale}`;
}

export function getApplicationId(mode: AuthMode): string {
  const id =
    mode === 'internal' ? __INTERNAL_APPLICATION_ID__ : __COMMERCIAL_APPLICATION_ID__;
  if (!id?.trim()) {
    throw new Error(
      mode === 'internal' ?
        'INTERNAL_APPLICATION_ID is not configured'
      : 'COMMERCIAL_APPLICATION_ID is not configured',
    );
  }
  return id.trim();
}

export function joinAuthUrl(path: string): string {
  const base = getAuthUpstreamBase();
  const normalized = path.startsWith('/') ? path : `/${path}`;
  return `${base}${normalized}`;
}
