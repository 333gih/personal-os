import { cookies } from "next/headers";
import { NextResponse } from "next/server";

import { postJson } from "@/lib/auth/backend";
import { COOKIE_REFRESH } from "@/lib/auth/constants";
import { clearTokenCookies } from "@/lib/auth/cookies";
import { backendFailureResponse, safeAuthRoute } from "@/lib/auth/route-handler";
import { getCookieSecureFromHeaders, getServerAuthEnv } from "@/lib/auth/server-env";
import type { LogoutRequest } from "@/lib/auth/types";

export async function POST(request: Request) {
  return safeAuthRoute(async () => {
    const jar = await cookies();
    const refresh = jar.get(COOKIE_REFRESH)?.value;
    const env = getServerAuthEnv();

    if (refresh) {
      const body: LogoutRequest = {
        refresh_token: refresh,
        application_id: env.APPLICATION_ID,
      };
      const result = await postJson("/api/v1/auth/logout", body);
      if (!result.ok && result.status !== 401) {
        return backendFailureResponse(result);
      }
    }

    const res = NextResponse.json({ ok: true });
    clearTokenCookies(res.cookies, {
      secure: getCookieSecureFromHeaders(request.headers),
    });
    return res;
  });
}
