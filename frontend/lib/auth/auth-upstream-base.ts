import "server-only";

import { getServerAuthEnv } from "./server-env";

function stripTrailingSlash(s: string): string {
  return s.replace(/\/+$/, "");
}

function stripTrailingLocaleSegment(url: string): string {
  return stripTrailingSlash(url).replace(/\/(?:vi|en)$/i, "");
}

export function authApiMountRootNormalized(): string {
  return stripTrailingSlash(stripTrailingLocaleSegment(getServerAuthEnv().API_URL));
}

export function authUpstreamBase(): string {
  const { AUTH_LOCALE } = getServerAuthEnv();
  return `${authApiMountRootNormalized()}/${AUTH_LOCALE}`;
}
