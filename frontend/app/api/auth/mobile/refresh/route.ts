import { NextResponse } from "next/server";

import { lockedRefresh } from "@/lib/auth/locked-refresh";
import { backendFailureResponse, safeAuthRoute } from "@/lib/auth/route-handler";

type MobileRefreshBody = {
  refresh_token?: string;
};

/** Native iOS: refresh access token using stored refresh token (no cookies). */
export async function POST(request: Request) {
  return safeAuthRoute(async () => {
    let body: MobileRefreshBody = {};
    try {
      body = (await request.json()) as MobileRefreshBody;
    } catch {
      return NextResponse.json({ error: "Invalid JSON body." }, { status: 400 });
    }

    const refresh = body.refresh_token?.trim();
    if (!refresh) {
      return NextResponse.json({ error: "Missing refresh_token." }, { status: 400 });
    }

    const result = await lockedRefresh(refresh);
    if (!result.ok) {
      return backendFailureResponse(result);
    }
    if (!result.data) {
      return NextResponse.json({ error: "Empty token response from upstream." }, { status: 502 });
    }

    return NextResponse.json(result.data);
  });
}
