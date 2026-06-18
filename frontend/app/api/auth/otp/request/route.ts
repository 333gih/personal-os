import { NextResponse } from "next/server";

import { postJson } from "@/lib/auth/backend";
import { clientChannelForMode, applicationIdForMode } from "@/lib/auth/modes";
import {
  backendFailureResponse,
  isValidEmail,
  readJsonBody,
  safeAuthRoute,
} from "@/lib/auth/route-handler";
import { getServerAuthEnv } from "@/lib/auth/server-env";
import type { OtpEmailRequest } from "@/lib/auth/types";

export async function POST(request: Request) {
  return safeAuthRoute(async () => {
    const parsed = await readJsonBody<{ email?: string }>(request);
    if (parsed instanceof NextResponse) return parsed;

    const email = parsed.email?.trim() ?? "";
    if (!isValidEmail(email)) {
      return NextResponse.json({ error: "Invalid email." }, { status: 400 });
    }

    const env = getServerAuthEnv();
    const body: OtpEmailRequest = {
      email,
      application_id: applicationIdForMode("commercial", env),
      client_channel: clientChannelForMode("commercial"),
    };

    const result = await postJson<{ is_new_user?: boolean }>("/api/v1/auth/otp/request", body);
    if (!result.ok) return backendFailureResponse(result);

    return NextResponse.json({
      ok: true,
      is_new_user: result.data?.is_new_user ?? false,
    });
  });
}
