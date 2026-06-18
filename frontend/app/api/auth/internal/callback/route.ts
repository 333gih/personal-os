import { NextResponse } from "next/server";

import { applyTokenCookies } from "@/lib/auth/cookies";
import { isAdminFromToken } from "@/lib/auth/internal-access";
import { sanitizeAppNext } from "@/lib/auth/safe-redirect";
import { verifySsoHandoffTicket } from "@/lib/auth/sso-handoff";
import { getCookieSecureFromHeaders, getServerAuthEnv } from "@/lib/auth/server-env";

function readSsoSecret(): string | null {
  const secret = process.env.PERSONAL_OS_SSO_HANDOFF_SECRET?.trim();
  if (!secret || secret.length < 32) return null;
  return secret;
}

export async function GET(request: Request) {
  try {
    const url = new URL(request.url);
    const ticket = url.searchParams.get("ticket")?.trim();
    const next = sanitizeAppNext(url.searchParams.get("next"));

    if (!ticket) {
      return NextResponse.redirect(new URL("/login?error=missing_ticket", url.origin));
    }

    const secret = readSsoSecret();
    if (!secret) {
      return NextResponse.redirect(new URL("/login?error=sso_not_configured", url.origin));
    }

    const payload = verifySsoHandoffTicket(ticket, secret);
    if (!payload) {
      return NextResponse.redirect(new URL("/login?error=invalid_ticket", url.origin));
    }

    if (!isAdminFromToken(payload.access_token)) {
      return NextResponse.redirect(new URL("/login?error=not_admin", url.origin));
    }

    getServerAuthEnv();

    const res = NextResponse.redirect(new URL(next, url.origin));
    applyTokenCookies(
      res.cookies,
      {
        access_token: payload.access_token,
        refresh_token: payload.refresh_token,
        token_type: "bearer",
        expires_in: payload.expires_in,
        refresh_expires_in: payload.refresh_expires_in,
      },
      false,
      { secure: getCookieSecureFromHeaders(request.headers) },
    );
    return res;
  } catch (e) {
    console.error("[internal/callback]", e);
    return NextResponse.redirect(new URL("/login?error=callback_failed", request.url));
  }
}
