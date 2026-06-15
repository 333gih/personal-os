import { NextResponse } from "next/server";

import { ensureSessionAccess } from "@/lib/auth/session";

export async function GET() {
  const session = await ensureSessionAccess();
  if (session.status !== "authenticated") {
    return NextResponse.json({ authenticated: false }, { status: 401 });
  }
  return NextResponse.json({ authenticated: true });
}
