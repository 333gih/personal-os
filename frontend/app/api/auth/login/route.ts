import { NextResponse } from "next/server";

import { postJson } from "@/lib/auth/backend";
import { applyTokenCookies } from "@/lib/auth/cookies";
import {
  backendFailureResponse,
  isValidEmail,
  readJsonBody,
  safeAuthRoute,
  validateLoginBody,
} from "@/lib/auth/route-handler";
import { getCookieSecureFromHeaders, getServerAuthEnv } from "@/lib/auth/server-env";
import type { LoginRequest, TokenResponse } from "@/lib/auth/types";

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
    const body: LoginRequest = {
      email,
      password,
      application_id: env.APPLICATION_ID,
    };

    console.log("[auth-bff] login attempt", { email, application_id: env.APPLICATION_ID });

    const result = await postJson<TokenResponse>("/api/v1/auth/login", body);
    if (!result.ok) {
      return backendFailureResponse(result);
    }
    if (!result.data) {
      return NextResponse.json({ error: "Empty token response from upstream." }, { status: 502 });
    }

    const rememberMe = parsed.remember_me === true;
    const res = NextResponse.json({ ok: true, expires_in: result.data.expires_in });
    applyTokenCookies(res.cookies, result.data, rememberMe, {
      secure: getCookieSecureFromHeaders(request.headers),
    });
    return res;
  });
}
