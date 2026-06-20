import { NextRequest } from "next/server";

import { forwardToPersonalOSApi } from "@/lib/api-upstream";

export const runtime = "nodejs";

/** Native iOS: Bearer-only BFF → internal personal-os-api (bypasses Kong 503). */
function bearerFrom(request: NextRequest): string | null {
  const header = request.headers.get("Authorization")?.trim();
  if (!header?.toLowerCase().startsWith("bearer ")) return null;
  return header.slice(7).trim() || null;
}

async function mobileProxy(request: NextRequest, pathSegments: string[]) {
  const token = bearerFrom(request);
  if (!token) {
    return Response.json({ error: "Missing Authorization Bearer token" }, { status: 401 });
  }
  return forwardToPersonalOSApi(request, pathSegments, token);
}

type RouteContext = { params: Promise<{ path: string[] }> };

export async function GET(request: NextRequest, context: RouteContext) {
  const { path } = await context.params;
  return mobileProxy(request, path);
}

export async function POST(request: NextRequest, context: RouteContext) {
  const { path } = await context.params;
  return mobileProxy(request, path);
}

export async function PUT(request: NextRequest, context: RouteContext) {
  const { path } = await context.params;
  return mobileProxy(request, path);
}

export async function PATCH(request: NextRequest, context: RouteContext) {
  const { path } = await context.params;
  return mobileProxy(request, path);
}

export async function DELETE(request: NextRequest, context: RouteContext) {
  const { path } = await context.params;
  return mobileProxy(request, path);
}
