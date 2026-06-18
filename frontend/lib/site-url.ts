/** Canonical public origin (metadata, SSO callback, redirects). */
export function getSiteBaseUrl(): string {
  const raw = process.env.NEXT_PUBLIC_SITE_URL?.trim() || "http://localhost:3000";
  return normalizeSiteOrigin(raw);
}

/** Map Docker bind addresses (0.0.0.0) to a browser-reachable origin. */
export function normalizeSiteOrigin(origin: string): string {
  try {
    const url = new URL(origin.replace(/\/+$/, "") || "http://localhost:3000");
    if (url.hostname === "0.0.0.0") {
      url.hostname = "localhost";
    }
    return url.origin;
  } catch {
    return "http://localhost:3000";
  }
}

/** Client-side origin for SSO return URL — prefer env over window when bind host. */
export function resolveClientSiteOrigin(): string {
  const fromEnv = process.env.NEXT_PUBLIC_SITE_URL?.trim();
  if (fromEnv) return normalizeSiteOrigin(fromEnv);

  if (typeof window === "undefined") return "http://localhost:3000";

  const { hostname, port, protocol } = window.location;
  if (hostname === "0.0.0.0" || hostname === "127.0.0.1") {
    const p = port || "3000";
    return normalizeSiteOrigin(`${protocol}//localhost:${p}`);
  }
  return normalizeSiteOrigin(window.location.origin);
}
