import { NextRequest, NextResponse } from "next/server";

import {
  PORTAL_COOKIE_REFRESH_401_HEADER,
  PORTAL_COOKIE_REFRESH_401_VALUE,
} from "@/lib/auth/constants";
import { ensureSessionAccess } from "@/lib/auth/session";
import { getServerAuthEnv } from "@/lib/auth/server-env";

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

  const { PERSONAL_OS_API_URL } = getServerAuthEnv();
  const upstreamPath = `/api/v1/${pathSegments.join("/")}`;
  const url = `${PERSONAL_OS_API_URL}${upstreamPath}${request.nextUrl.search}`;

  const headers = new Headers();
  const contentType = request.headers.get("content-type");
  if (contentType) headers.set("Content-Type", contentType);
  headers.set("Authorization", `Bearer ${bearer}`);
  headers.set("Accept", request.headers.get("accept") || "application/json");

  const hasBody = request.method !== "GET" && request.method !== "HEAD";
  const init: RequestInit & { duplex?: "half" } = {
    method: request.method,
    headers,
    cache: "no-store",
  };
  if (hasBody) {
    init.body = request.body;
    init.duplex = "half";
  }

  const upstream = await fetch(url, init);
  const responseHeaders = new Headers();
  const upstreamType = upstream.headers.get("content-type");
  if (upstreamType) responseHeaders.set("Content-Type", upstreamType);

  return new NextResponse(upstream.body, {
    status: upstream.status,
    headers: responseHeaders,
  });
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
