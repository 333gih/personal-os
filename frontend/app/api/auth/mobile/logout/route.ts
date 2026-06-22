import { NextResponse } from "next/server";

import { postJson } from "@/lib/auth/backend";
import { backendFailureResponse, safeAuthRoute } from "@/lib/auth/route-handler";
import { getServerAuthEnv } from "@/lib/auth/server-env";
import type { LogoutRequest } from "@/lib/auth/types";

type MobileLogoutBody = {
  refresh_token?: string;
};

/** Native iOS: revoke refresh token on sign-out (no cookies). */
export async function POST(request: Request) {
  return safeAuthRoute(async () => {
    let body: MobileLogoutBody = {};
    try {
      body = (await request.json()) as MobileLogoutBody;
    } catch {
      return NextResponse.json({ error: "Invalid JSON body." }, { status: 400 });
    }

    const refresh = body.refresh_token?.trim();
    if (!refresh) {
      return NextResponse.json({ ok: true });
    }

    const env = getServerAuthEnv();
    const payload: LogoutRequest = {
      refresh_token: refresh,
      application_id: env.APPLICATION_ID,
    };

    const result = await postJson("/api/v1/auth/logout", payload);
    if (!result.ok && result.status !== 401) {
      return backendFailureResponse(result);
    }

    return NextResponse.json({ ok: true });
  });
}
