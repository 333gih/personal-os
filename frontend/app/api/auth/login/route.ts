import { NextResponse } from "next/server";

import { postJson } from "@/lib/auth/backend";
import { applyTokenCookies } from "@/lib/auth/cookies";
import type { AuthMode } from "@/lib/auth/channels";
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
  mode?: AuthMode;
};

function parseMode(value: unknown): AuthMode {
  return value === "internal" ? "internal" : "commercial";
}

export async function POST(request: Request) {
  return safeAuthRoute(async () => {
    const parsed = await readJsonBody<unknown>(request);
    if (parsed instanceof NextResponse) return parsed;
    if (!validateLoginBody(parsed)) {
      return NextResponse.json({ error: "Expected { email, password }" }, { status: 400 });
    }

    const body = parsed as LoginBody;
    const { email, password } = body;
    const mode = parseMode(body.mode);

    if (!isValidEmail(email) || password.length < 8 || password.length > 256) {
      return NextResponse.json({ error: "Invalid email or password format." }, { status: 400 });
    }

    const env = getServerAuthEnv();
    const upstream: LoginRequest = {
      email,
      password,
      application_id: applicationIdForMode(mode, env),
      client_channel: clientChannelForMode(mode),
    };

    const result = await postJson<TokenResponse>("/api/v1/auth/login", upstream);
    if (!result.ok) {
      return backendFailureResponse(result);
    }
    if (!result.data) {
      return NextResponse.json({ error: "Empty token response from upstream." }, { status: 502 });
    }

    if (mode === "internal" && !result.data.user?.is_admin) {
      return NextResponse.json(
        { error: "Access denied. Internal login requires an admin account." },
        { status: 403 },
      );
    }

    const rememberMe = body.remember_me === true;
    const res = NextResponse.json({ ok: true, expires_in: result.data.expires_in, mode });
    applyTokenCookies(res.cookies, result.data, rememberMe, {
      secure: getCookieSecureFromHeaders(request.headers),
    });
    return res;
  });
}
