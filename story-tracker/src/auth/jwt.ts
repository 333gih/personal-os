export function decodeJwtPayload(token: string): Record<string, unknown> | null {
  const parts = token.split('.');
  if (parts.length < 2) return null;
  const segment = parts[1];
  if (!segment) return null;
  try {
    const base64 = segment.replace(/-/g, '+').replace(/_/g, '/');
    const padded = base64.padEnd(base64.length + ((4 - (base64.length % 4)) % 4), '=');
    const json = atob(padded);
    return JSON.parse(json) as Record<string, unknown>;
  } catch {
    return null;
  }
}

export function isAccessTokenExpired(token: string, skewSeconds = 45): boolean {
  const payload = decodeJwtPayload(token);
  const exp = payload && typeof payload.exp === 'number' ? payload.exp : null;
  if (exp === null) return true;
  const now = Math.floor(Date.now() / 1000);
  return now >= exp - skewSeconds;
}

export function isAdminFromToken(accessToken: string): boolean {
  const payload = decodeJwtPayload(accessToken);
  if (!payload) return false;

  const candidates = [payload.admin, payload.is_admin, payload.isAdmin];
  return candidates.some((value) => value === true || value === 'true' || value === 1);
}

export function userFromToken(accessToken: string): {
  id: string;
  email: string;
  name?: string;
  isAdmin: boolean;
} {
  const payload = decodeJwtPayload(accessToken) ?? {};
  const id =
    (typeof payload.user_id === 'string' && payload.user_id) ||
    (typeof payload.sub === 'string' && payload.sub) ||
    'unknown';
  const email = typeof payload.email === 'string' ? payload.email : '';
  const name =
    (typeof payload.name === 'string' && payload.name) ||
    (typeof payload.full_name === 'string' && payload.full_name) ||
    undefined;

  return {
    id,
    email,
    name,
    isAdmin: isAdminFromToken(accessToken),
  };
}
