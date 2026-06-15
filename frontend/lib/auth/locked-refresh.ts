import "server-only";

import type { BackendResult } from "./backend";
import { postJson } from "./backend";
import { getServerAuthEnv } from "./server-env";
import type { RefreshRequest, TokenResponse } from "./types";

const locks = new Map<string, Promise<BackendResult<TokenResponse>>>();

export async function lockedRefresh(refreshToken: string): Promise<BackendResult<TokenResponse>> {
  const cached = locks.get(refreshToken);
  if (cached) return cached;

  const env = getServerAuthEnv();
  const body: RefreshRequest = {
    refresh_token: refreshToken,
    application_id: env.APPLICATION_ID,
  };

  const started = postJson<TokenResponse>("/api/v1/auth/refresh", body).finally(() => {
    locks.delete(refreshToken);
  });
  locks.set(refreshToken, started);
  return started;
}
