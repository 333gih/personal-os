import { NextResponse } from "next/server";

import { postJson } from "@/lib/auth/backend";
import { applyTokenCookies } from "@/lib/auth/cookies";
import { clientChannelForMode, applicationIdForMode } from "@/lib/auth/modes";
import {
  backendFailureResponse,
  isValidEmail,
  readJsonBody,
  safeAuthRoute,
} from "@/lib/auth/route-handler";
import { getCookieSecureFromHeaders, getServerAuthEnv } from "@/lib/auth/server-env";
import type { OtpVerifyRequest, TokenResponse } from "@/lib/auth/types";

export async function POST(request: Request) {
  return safeAuthRoute(async () => {
    const parsed = await readJsonBody<{
      email?: string;
      otp?: string;
      code?: string;
      remember_me?: boolean;
    }>(request);
    if (parsed instanceof NextResponse) return parsed;

    const email = parsed.email?.trim() ?? "";
    const otp = (parsed.otp ?? parsed.code ?? "").trim();
    if (!isValidEmail(email) || otp.length < 4) {
      return NextResponse.json({ error: "Expected valid email and OTP code." }, { status: 400 });
    }

    const env = getServerAuthEnv();
    const body: OtpVerifyRequest = {
      email,
      application_id: applicationIdForMode("commercial", env),
      otp,
      client_channel: clientChannelForMode("commercial"),
    };

    const result = await postJson<TokenResponse>("/api/v1/auth/otp/verify", body);
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
