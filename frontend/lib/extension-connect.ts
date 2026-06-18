import { normalizeSiteOrigin } from "@/lib/site-url";

/** Production FE — extension content script only matches this host. */
const DEFAULT_EXTENSION_CONNECT_ORIGIN = "https://personal-os-fe.fashandcurious.com";

function isLocalOrigin(origin: string): boolean {
  try {
    const host = new URL(origin).hostname.toLowerCase();
    return host === "localhost" || host === "127.0.0.1" || host === "0.0.0.0";
  } catch {
    return false;
  }
}

/** Canonical origin for Story Tracker handoff (never localhost). */
export function getExtensionConnectOrigin(): string {
  const candidates = [
    process.env.NEXT_PUBLIC_EXTENSION_CONNECT_ORIGIN?.trim(),
    process.env.NEXT_PUBLIC_SITE_URL?.trim(),
  ].filter(Boolean) as string[];

  for (const raw of candidates) {
    const origin = normalizeSiteOrigin(raw);
    if (!isLocalOrigin(origin)) return origin;
  }

  return normalizeSiteOrigin(DEFAULT_EXTENSION_CONNECT_ORIGIN);
}

export function isExtensionConnectPath(path: string): boolean {
  const pathname = (path.split("?")[0] ?? path).trim();
  return pathname === "/extension/connect" || pathname.startsWith("/extension/connect/");
}

export function buildExtensionConnectUrl(pathAndQuery: string): string {
  const path = pathAndQuery.startsWith("/") ? pathAndQuery : `/${pathAndQuery}`;
  return new URL(path, getExtensionConnectOrigin()).href;
}

/** Redirect off localhost/dev host so extension bridge + SSO callback stay on prod. */
export function ensureCanonicalExtensionConnectHost(): boolean {
  if (typeof window === "undefined") return false;

  const canonical = getExtensionConnectOrigin();
  if (window.location.origin === canonical) return false;

  const target = `${canonical}${window.location.pathname}${window.location.search}`;
  window.location.replace(target);
  return true;
}
