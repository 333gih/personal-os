import { cookies } from "next/headers";
import { NextResponse } from "next/server";

import { COOKIE_REFRESH } from "@/lib/auth/constants";
import { applyTokenCookies, readAuthPersistMarker } from "@/lib/auth/cookies";
import { lockedRefresh } from "@/lib/auth/locked-refresh";
import { backendFailureResponse, safeAuthRoute } from "@/lib/auth/route-handler";
import { getCookieSecureFromHeaders } from "@/lib/auth/server-env";

export async function POST(request: Request) {
  return safeAuthRoute(async () => {
    const jar = await cookies();
    const refresh = jar.get(COOKIE_REFRESH)?.value;
    if (!refresh) {
      return NextResponse.json({ error: "No refresh session." }, { status: 401 });
    }
    const persistent = readAuthPersistMarker(jar);

    const result = await lockedRefresh(refresh);
    if (!result.ok) {
      return backendFailureResponse(result);
    }
    if (!result.data) {
      return NextResponse.json({ error: "Empty token response from upstream." }, { status: 502 });
    }

    const res = NextResponse.json({ ok: true, expires_in: result.data.expires_in });
    applyTokenCookies(res.cookies, result.data, persistent, {
      secure: getCookieSecureFromHeaders(request.headers),
    });
    return res;
  });
}
