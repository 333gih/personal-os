import "server-only";

import { hasInternalAppAccess, isAdminFromToken } from "./internal-access";
import type { AuthMode } from "./channels";
import { getServerAuthEnv } from "./server-env";

export function inferAuthModeFromAccessToken(accessToken: string): AuthMode {
  const env = getServerAuthEnv();
  const internalAppId = env.INTERNAL_APPLICATION_ID?.trim() || "personal-os-internal";
  if (isAdminFromToken(accessToken) && hasInternalAppAccess(accessToken, internalAppId)) {
    return "internal";
  }
  return "commercial";
}
