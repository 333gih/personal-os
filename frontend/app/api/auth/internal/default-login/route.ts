import { NextResponse } from "next/server";

import { applyTokenCookies } from "@/lib/auth/cookies";
import { AUTH_CLIENT_CHANNELS } from "@/lib/auth/channels";
import { executeProvisionedInternalLogin } from "@/lib/auth/internal-login";
import { safeAuthRoute } from "@/lib/auth/route-handler";
import { getCookieSecureFromHeaders, getServerAuthEnv } from "@/lib/auth/server-env";

export async function POST(request: Request) {
  return safeAuthRoute(async () => {
    const env = getServerAuthEnv();
    const enabled =
      env.internalDefaultLoginEnabled || process.env.NODE_ENV === "development";
    if (!enabled) {
      return NextResponse.json({ error: "Default internal login is disabled." }, { status: 403 });
    }

    const email = env.INTERNAL_DEFAULT_USER_EMAIL;
    const password = env.INTERNAL_DEFAULT_USER_PASSWORD;
    if (!email || !password) {
      return NextResponse.json(
        { error: "Default internal credentials are not configured on this deployment." },
        { status: 503 },
      );
    }

    const result = await executeProvisionedInternalLogin(email, password, env);
    if (!result.ok) {
      return NextResponse.json({ error: result.error }, { status: result.status });
    }

    const parsed = await request.json().catch(() => ({}));
    const rememberMe =
      typeof parsed === "object" &&
      parsed !== null &&
      (parsed as { remember_me?: boolean }).remember_me === true;

    const res = NextResponse.json({
      ok: true,
      expires_in: result.data.expires_in,
      mode: "internal",
      channel: AUTH_CLIENT_CHANNELS.PERSONAL_OS_WEB_INTERNAL_DEFAULT,
    });
    applyTokenCookies(res.cookies, result.data, rememberMe, {
      secure: getCookieSecureFromHeaders(request.headers),
    });
    return res;
  });
}
