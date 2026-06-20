import { NextResponse } from "next/server";

import { readTokensFromCookies } from "@/lib/auth/cookies";
import { inferAuthModeFromAccessToken } from "@/lib/auth/infer-auth-mode";
import { isAdminFromToken } from "@/lib/auth/internal-access";
import { decodeJwtPayload } from "@/lib/auth/jwt";
import { applicationIdForMode } from "@/lib/auth/modes";
import { ensureSessionAccess } from "@/lib/auth/session";
import { getServerAuthEnv } from "@/lib/auth/server-env";

function expiresInFromToken(token: string, fallback: number): number {
  const payload = decodeJwtPayload(token);
  const exp = payload && typeof payload.exp === "number" ? payload.exp : null;
  if (exp === null) return fallback;
  return Math.max(60, exp - Math.floor(Date.now() / 1000));
}

/** Native iOS: exchange portal cookies for a full token bundle after WebView login. */
export async function GET() {
  const session = await ensureSessionAccess();
  if (session.status !== "authenticated") {
    return NextResponse.json({ error: "Not authenticated" }, { status: 401 });
  }

  const { access, refresh } = await readTokensFromCookies();
  if (!access || !refresh) {
    return NextResponse.json({ error: "Not authenticated" }, { status: 401 });
  }

  const env = getServerAuthEnv();
  const mode = inferAuthModeFromAccessToken(access);

  if (mode === "internal" && !isAdminFromToken(access)) {
    return NextResponse.json({ error: "Internal session requires admin access." }, { status: 403 });
  }

  return NextResponse.json({
    access_token: access,
    refresh_token: refresh,
    token_type: "bearer" as const,
    expires_in: expiresInFromToken(access, 3600),
    refresh_expires_in: expiresInFromToken(refresh, 604800),
    mode,
    application_id: applicationIdForMode(mode, env),
  });
}
