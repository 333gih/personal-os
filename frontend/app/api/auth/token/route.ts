import { NextResponse } from "next/server";

import {
  PORTAL_COOKIE_REFRESH_401_HEADER,
  PORTAL_COOKIE_REFRESH_401_VALUE,
} from "@/lib/auth/constants";
import { ensureSessionAccess } from "@/lib/auth/session";

export async function GET() {
  const session = await ensureSessionAccess();
  if (session.status !== "authenticated") {
    return NextResponse.json(
      { error: "Not authenticated" },
      {
        status: 401,
        headers: {
          [PORTAL_COOKIE_REFRESH_401_HEADER]: PORTAL_COOKIE_REFRESH_401_VALUE,
        },
      },
    );
  }
  return NextResponse.json({ access_token: session.accessToken });
}
