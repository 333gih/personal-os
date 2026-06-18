import { NextResponse } from "next/server";

import { applyTokenCookies } from "@/lib/auth/cookies";
import { isAdminFromToken } from "@/lib/auth/internal-access";
import { sanitizeAppNext } from "@/lib/auth/safe-redirect";
import { verifySsoHandoffTicket } from "@/lib/auth/sso-handoff";
import { getCookieSecureFromHeaders, getServerAuthEnv } from "@/lib/auth/server-env";
import { absolutePublicUrl } from "@/lib/request-public-origin";

function readSsoSecret(): string | null {
  const secret = process.env.PERSONAL_OS_SSO_HANDOFF_SECRET?.trim();
  if (!secret || secret.length < 32) return null;
  return secret;
}

export async function GET(request: Request) {
  const headers = request.headers;
  try {
    const url = new URL(request.url);
    const ticket = url.searchParams.get("ticket")?.trim();
    const next = sanitizeAppNext(url.searchParams.get("next"));

    if (!ticket) {
      return NextResponse.redirect(absolutePublicUrl(headers, "/login?error=missing_ticket"));
    }

    const secret = readSsoSecret();
    if (!secret) {
      return NextResponse.redirect(absolutePublicUrl(headers, "/login?error=sso_not_configured"));
    }

    const payload = verifySsoHandoffTicket(ticket, secret);
    if (!payload) {
      return NextResponse.redirect(absolutePublicUrl(headers, "/login?error=invalid_ticket"));
    }

    if (!isAdminFromToken(payload.access_token)) {
      return NextResponse.redirect(absolutePublicUrl(headers, "/login?error=not_admin"));
    }

    getServerAuthEnv();

    const res = NextResponse.redirect(absolutePublicUrl(headers, next));
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
    return NextResponse.redirect(absolutePublicUrl(request.headers, "/login?error=callback_failed"));
  }
}
