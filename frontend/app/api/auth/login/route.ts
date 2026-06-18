import { NextResponse } from "next/server";

import { postJson } from "@/lib/auth/backend";
import { applyTokenCookies } from "@/lib/auth/cookies";
import { clientChannelForMode, applicationIdForMode } from "@/lib/auth/modes";
import {
  backendFailureResponse,
  isValidEmail,
  readJsonBody,
  safeAuthRoute,
  validateLoginBody,
} from "@/lib/auth/route-handler";
import { getCookieSecureFromHeaders, getServerAuthEnv } from "@/lib/auth/server-env";
import type { LoginRequest, TokenResponse } from "@/lib/auth/types";

type LoginBody = {
  email: string;
  password: string;
  remember_me?: boolean;
  mode?: string;
};

export async function POST(request: Request) {
  return safeAuthRoute(async () => {
    const parsed = await readJsonBody<unknown>(request);
    if (parsed instanceof NextResponse) return parsed;
    if (!validateLoginBody(parsed)) {
      return NextResponse.json({ error: "Expected { email, password }" }, { status: 400 });
    }

    const body = parsed as LoginBody;
    if (body.mode === "internal") {
      return NextResponse.json(
        {
          error:
            "Internal login is not available here. Use Admin Portal provisioning or the default internal account option.",
        },
        { status: 400 },
      );
    }

    const { email, password } = body;

    if (!isValidEmail(email) || password.length < 8 || password.length > 256) {
      return NextResponse.json({ error: "Invalid email or password format." }, { status: 400 });
    }

    const env = getServerAuthEnv();
    const upstream: LoginRequest = {
      email,
      password,
      application_id: applicationIdForMode("commercial", env),
      client_channel: clientChannelForMode("commercial"),
    };

    const result = await postJson<TokenResponse>("/api/v1/auth/login", upstream);
    if (!result.ok) {
      return backendFailureResponse(result);
    }
    if (!result.data) {
      return NextResponse.json({ error: "Empty token response from upstream." }, { status: 502 });
    }

    const rememberMe = body.remember_me === true;
    const res = NextResponse.json({ ok: true, expires_in: result.data.expires_in, mode: "commercial" });
    applyTokenCookies(res.cookies, result.data, rememberMe, {
      secure: getCookieSecureFromHeaders(request.headers),
    });
    return res;
  });
}
