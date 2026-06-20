import "server-only";

import { NextRequest, NextResponse } from "next/server";
import { getServerAuthEnv } from "@/lib/auth/server-env";

/** Base URL for server-side upstream (prefer Docker internal DNS). */
export function getPersonalOSUpstreamBase(): string {
  const env = getServerAuthEnv();
  const internal = env.PERSONAL_OS_API_INTERNAL_URL?.replace(/\/+$/, "");
  if (internal) return internal;
  return env.PERSONAL_OS_API_URL.replace(/\/+$/, "");
}

export async function forwardToPersonalOSApi(
  request: NextRequest,
  pathSegments: string[],
  bearerToken: string,
): Promise<NextResponse> {
  const url = `${getPersonalOSUpstreamBase()}/api/v1/${pathSegments.join("/")}${request.nextUrl.search}`;

  const headers = new Headers();
  const contentType = request.headers.get("content-type");
  if (contentType) headers.set("Content-Type", contentType);
  headers.set("Authorization", `Bearer ${bearerToken}`);
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

  let upstream: Response;
  try {
    upstream = await fetch(url, init);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Upstream unreachable";
    return NextResponse.json(
      { error: "Personal OS API unreachable", detail: message },
      { status: 502 },
    );
  }

  const responseHeaders = new Headers();
  const upstreamType = upstream.headers.get("content-type");
  if (upstreamType) responseHeaders.set("Content-Type", upstreamType);

  return new NextResponse(upstream.body, {
    status: upstream.status,
    headers: responseHeaders,
  });
}
