import "server-only";

import { createHmac, timingSafeEqual } from "crypto";

export const SSO_AUDIENCE = "personal-os-internal-sso";

export type SsoHandoffPayload = {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  refresh_expires_in: number;
  exp: number;
  aud: typeof SSO_AUDIENCE;
};

function sign(body: string, secret: string): string {
  return createHmac("sha256", secret).update(body).digest("base64url");
}

export function createSsoHandoffTicket(
  tokens: {
    access_token: string;
    refresh_token: string;
    expires_in: number;
    refresh_expires_in: number;
  },
  secret: string,
  ttlSeconds = 60,
): string {
  const payload: SsoHandoffPayload = {
    access_token: tokens.access_token,
    refresh_token: tokens.refresh_token,
    expires_in: tokens.expires_in,
    refresh_expires_in: tokens.refresh_expires_in,
    aud: SSO_AUDIENCE,
    exp: Math.floor(Date.now() / 1000) + ttlSeconds,
  };
  const body = Buffer.from(JSON.stringify(payload)).toString("base64url");
  return `${body}.${sign(body, secret)}`;
}

export function verifySsoHandoffTicket(ticket: string, secret: string): SsoHandoffPayload | null {
  const trimmed = ticket.trim();
  const dot = trimmed.lastIndexOf(".");
  if (dot <= 0) return null;

  const body = trimmed.slice(0, dot);
  const sig = trimmed.slice(dot + 1);
  const expected = sign(body, secret);

  try {
    const a = Buffer.from(sig);
    const b = Buffer.from(expected);
    if (a.length !== b.length || !timingSafeEqual(a, b)) return null;
  } catch {
    return null;
  }

  try {
    const json = JSON.parse(Buffer.from(body, "base64url").toString("utf8")) as SsoHandoffPayload;
    if (json.aud !== SSO_AUDIENCE) return null;
    if (typeof json.exp !== "number" || json.exp < Math.floor(Date.now() / 1000)) return null;
    if (!json.access_token?.trim() || !json.refresh_token?.trim()) return null;
    return json;
  } catch {
    return null;
  }
}
