export const EXTENSION_HANDOFF_MESSAGE_TYPE = 'PERSONAL_OS_EXTENSION_HANDOFF';

export type WebAuthHandoffPayload = {
  access_token: string;
  refresh_token: string;
  token_type: 'bearer';
  expires_in: number;
  refresh_expires_in: number;
  mode: 'internal' | 'commercial';
  application_id: string;
  nonce: string | null;
};

function stripTrailingSlash(url: string): string {
  return url.replace(/\/+$/, '');
}

export function getPersonalOsFeOrigin(): string {
  const raw = (__PERSONAL_OS_FE_URL__ || 'https://personal-os-fe.fashandcurious.com').trim();
  return stripTrailingSlash(raw);
}

export function buildExtensionConnectUrl(nonce: string): string {
  const url = new URL(`${getPersonalOsFeOrigin()}/extension/connect`);
  url.searchParams.set('nonce', nonce);
  return url.toString();
}

export function personalOsFeConnectMatches(): string[] {
  const origin = getPersonalOsFeOrigin();
  if (origin.includes('localhost') || origin.includes('127.0.0.1')) {
    return [`${origin}/extension/connect*`];
  }
  return [`${origin}/extension/connect*`];
}
