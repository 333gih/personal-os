import "server-only";

import { postJson } from "./backend";
import { clientChannelForMode, applicationIdForMode } from "./modes";
import { hasInternalAppAccess, isAdminFromToken } from "./internal-access";
import type { ServerAuthEnv } from "./server-env";
import type { TokenResponse } from "./types";

export type InternalLoginResult =
  | { ok: true; data: TokenResponse; applicationId: string }
  | { ok: false; status: number; error: string };

export async function executeProvisionedInternalLogin(
  email: string,
  password: string,
  env: ServerAuthEnv,
): Promise<InternalLoginResult> {
  const applicationId = applicationIdForMode("internal", env);

  const result = await postJson<TokenResponse>("/api/v1/auth/admin/login", {
    email,
    password,
    application_id: applicationId,
    client_channel: clientChannelForMode("internal"),
  });

  if (!result.ok) {
    const readable =
      typeof result.json === "object" &&
      result.json !== null &&
      typeof (result.json as { message?: string }).message === "string"
        ? (result.json as { message: string }).message
        : result.text || "Login failed";
    return { ok: false, status: result.status || 502, error: readable };
  }

  if (!result.data?.access_token) {
    return { ok: false, status: 502, error: "Empty token response from upstream." };
  }

  if (!isAdminFromToken(result.data.access_token)) {
    return {
      ok: false,
      status: 403,
      error: "Access denied. Internal staff must be provisioned as an admin in the Admin Portal.",
    };
  }

  if (!hasInternalAppAccess(result.data.access_token, applicationId)) {
    return {
      ok: false,
      status: 403,
      error:
        "Access denied. Your account is not granted Personal OS access yet. Ask an admin to assign the application in the Admin Portal.",
    };
  }

  return { ok: true, data: result.data, applicationId };
}
