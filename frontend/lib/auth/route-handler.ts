import { NextResponse } from "next/server";

import type { BackendResult } from "./backend";

export type FailedBackendResult = Extract<BackendResult<unknown>, { ok: false }>;

function upstreamErrorMessage(json: unknown, fallback: string): string {
  if (typeof json === "object" && json !== null) {
    const o = json as Record<string, unknown>;
    if (typeof o.message === "string" && o.message) return o.message;
    if (typeof o.error === "string" && o.error) return o.error;
    if (typeof o.detail === "string" && o.detail) return o.detail;
  }
  return fallback;
}

export async function safeAuthRoute(fn: () => Promise<NextResponse>): Promise<NextResponse> {
  try {
    return await fn();
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg.startsWith("Missing API_URL") || msg.startsWith("Missing NEXT_PUBLIC_APP_ID")) {
      return NextResponse.json(
        { error: "Authentication service is not configured on this deployment." },
        { status: 503 },
      );
    }
    console.error("[auth-route]", e);
    return NextResponse.json({ error: "Internal server error." }, { status: 500 });
  }
}

export function backendFailureResponse(result: FailedBackendResult): NextResponse {
  if (result.status === 0) {
    return NextResponse.json(
      { error: "Unable to reach authentication service.", detail: result.text },
      { status: 502 },
    );
  }
  const readable = upstreamErrorMessage(
    result.json,
    typeof result.text === "string" ? result.text : "Upstream rejected the request.",
  );
  return NextResponse.json(
    { error: readable, detail: result.json ?? result.text },
    { status: result.status },
  );
}

export function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

export async function readJsonBody<T>(request: Request): Promise<T | NextResponse> {
  try {
    return (await request.json()) as T;
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }
}

export function validateLoginBody(
  body: unknown,
): body is { email: string; password: string; remember_me?: boolean } {
  if (typeof body !== "object" || body === null) return false;
  const o = body as Record<string, unknown>;
  return typeof o.email === "string" && typeof o.password === "string";
}
