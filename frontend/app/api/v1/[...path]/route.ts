import { NextRequest, NextResponse } from "next/server";

import {
  PORTAL_COOKIE_REFRESH_401_HEADER,
  PORTAL_COOKIE_REFRESH_401_VALUE,
} from "@/lib/auth/constants";
import { forwardToPersonalOSApi } from "@/lib/api-upstream";
import { ensureSessionAccess } from "@/lib/auth/session";

export const runtime = "nodejs";

function resolveBearer(request: NextRequest, sessionToken: string): string | null {
  const incoming = request.headers.get("Authorization")?.trim();
  if (incoming?.toLowerCase().startsWith("bearer ")) {
    const token = incoming.slice(7).trim();
    if (token) return token;
  }
  return sessionToken || null;
}

async function proxy(request: NextRequest, pathSegments: string[]) {
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

  const bearer = resolveBearer(request, session.accessToken);
  if (!bearer) {
    return NextResponse.json({ error: "Not authenticated" }, { status: 401 });
  }

  return forwardToPersonalOSApi(request, pathSegments, bearer);
}

type RouteContext = { params: Promise<{ path: string[] }> };

export async function GET(request: NextRequest, context: RouteContext) {
  const { path } = await context.params;
  return proxy(request, path);
}

export async function POST(request: NextRequest, context: RouteContext) {
  const { path } = await context.params;
  return proxy(request, path);
}

export async function PUT(request: NextRequest, context: RouteContext) {
  const { path } = await context.params;
  return proxy(request, path);
}

export async function PATCH(request: NextRequest, context: RouteContext) {
  const { path } = await context.params;
  return proxy(request, path);
}

export async function DELETE(request: NextRequest, context: RouteContext) {
  const { path } = await context.params;
  return proxy(request, path);
}
