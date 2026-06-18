import { NextResponse } from "next/server";

import { applyTokenCookies } from "@/lib/auth/cookies";
import { executeProvisionedInternalLogin } from "@/lib/auth/internal-login";
import {
  backendFailureResponse,
  isValidEmail,
  readJsonBody,
  safeAuthRoute,
  validateLoginBody,
} from "@/lib/auth/route-handler";
import { getCookieSecureFromHeaders, getServerAuthEnv } from "@/lib/auth/server-env";

export async function POST(request: Request) {
  return safeAuthRoute(async () => {
    const parsed = await readJsonBody<unknown>(request);
    if (parsed instanceof NextResponse) return parsed;
    if (!validateLoginBody(parsed)) {
      return NextResponse.json({ error: "Expected { email, password }" }, { status: 400 });
    }

    const { email, password } = parsed;
    if (!isValidEmail(email) || password.length < 8 || password.length > 256) {
      return NextResponse.json({ error: "Invalid email or password format." }, { status: 400 });
    }

    const env = getServerAuthEnv();
    const result = await executeProvisionedInternalLogin(email, password, env);
    if (!result.ok) {
      if (result.status >= 500) {
        return NextResponse.json({ error: result.error }, { status: result.status });
      }
      return NextResponse.json({ error: result.error }, { status: result.status });
    }

    const rememberMe =
      typeof parsed === "object" &&
      parsed !== null &&
      (parsed as { remember_me?: boolean }).remember_me === true;

    const res = NextResponse.json({
      ok: true,
      expires_in: result.data.expires_in,
      mode: "internal",
      channel: "personal_os_web_internal",
    });
    applyTokenCookies(res.cookies, result.data, rememberMe, {
      secure: getCookieSecureFromHeaders(request.headers),
    });
    return res;
  });
}
