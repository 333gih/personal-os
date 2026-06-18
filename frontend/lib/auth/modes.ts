import type { AuthMode } from "./channels";
import { AUTH_CLIENT_CHANNELS } from "./channels";

export function clientChannelForMode(mode: AuthMode): string {
  return mode === "internal"
    ? AUTH_CLIENT_CHANNELS.PERSONAL_OS_WEB_INTERNAL
    : AUTH_CLIENT_CHANNELS.PERSONAL_OS_WEB_COMMERCIAL;
}

export function applicationIdForMode(
  mode: AuthMode,
  env: {
    APPLICATION_ID: string;
    INTERNAL_APPLICATION_ID?: string;
    COMMERCIAL_APPLICATION_ID?: string;
  },
): string {
  if (mode === "internal") {
    return env.INTERNAL_APPLICATION_ID?.trim() || env.APPLICATION_ID;
  }
  return env.COMMERCIAL_APPLICATION_ID?.trim() || env.APPLICATION_ID;
}
