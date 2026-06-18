import { NextResponse } from "next/server";

import { postJson } from "@/lib/auth/backend";
import { applyTokenCookies } from "@/lib/auth/cookies";
import type { AuthMode } from "@/lib/auth/channels";
import { clientChannelForMode, applicationIdForMode } from "@/lib/auth/modes";
import {
  backendFailureResponse,
  readJsonBody,
  safeAuthRoute,
} from "@/lib/auth/route-handler";
import { getCookieSecureFromHeaders, getServerAuthEnv } from "@/lib/auth/server-env";
import type { SocialLoginRequest, TokenResponse } from "@/lib/auth/types";

export async function POST(request: Request) {
  return safeAuthRoute(async () => {
    const parsed = await readJsonBody<{
      provider?: string;
      provider_token?: string;
      mode?: AuthMode;
      remember_me?: boolean;
    }>(request);
    if (parsed instanceof NextResponse) return parsed;

    const provider = parsed.provider?.trim().toLowerCase();
    const providerToken = parsed.provider_token?.trim();
    if (!provider || !providerToken) {
      return NextResponse.json({ error: "Expected { provider, provider_token }" }, { status: 400 });
    }

    const mode: AuthMode = parsed.mode === "internal" ? "internal" : "commercial";
    if (mode === "internal") {
      return NextResponse.json({ error: "Social login is only available for commercial accounts." }, { status: 400 });
    }

    const env = getServerAuthEnv();
    const body: SocialLoginRequest = {
      provider,
      provider_token: providerToken,
      application_id: applicationIdForMode(mode, env),
      client_channel: clientChannelForMode(mode),
    };

    const result = await postJson<TokenResponse>("/api/v1/auth/social-login", body);
    if (!result.ok) return backendFailureResponse(result);
    if (!result.data) {
      return NextResponse.json({ error: "Empty token response from upstream." }, { status: 502 });
    }

    const res = NextResponse.json({
      ok: true,
      expires_in: result.data.expires_in,
      is_new_user: (result.data as TokenResponse & { is_new_user?: boolean }).is_new_user ?? false,
    });
    applyTokenCookies(res.cookies, result.data, parsed.remember_me === true, {
      secure: getCookieSecureFromHeaders(request.headers),
    });
    return res;
  });
}
