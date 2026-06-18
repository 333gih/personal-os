const DEFAULT_ALLOWED_PREFIXES = [
  "/dashboard",
  "/inbox",
  "/learning",
  "/work",
  "/startup",
  "/entertainment",
  "/search",
  "/settings",
  "/entities",
  "/extension/connect",
] as const;

function pathOnly(next: string): string {
  return next.split("?")[0] ?? next;
}

export function sanitizeAppNext(
  next: string | null | undefined,
  fallback = "/dashboard",
): string {
  if (!next || typeof next !== "string") return fallback;
  const value = next.trim();
  if (!value.startsWith("/") || value.startsWith("//") || value.includes("://")) {
    return fallback;
  }
  const pathname = pathOnly(value);
  for (const prefix of DEFAULT_ALLOWED_PREFIXES) {
    if (pathname === prefix || pathname.startsWith(`${prefix}/`)) {
      return value;
    }
  }
  return fallback;
}

export function isAllowedSsoCallbackUrl(url: string, allowedOrigins: string[]): boolean {
  try {
    const parsed = new URL(url);
    if (parsed.pathname !== "/api/auth/internal/callback") return false;
    if (parsed.protocol !== "https:" && parsed.protocol !== "http:") return false;
    return allowedOrigins.some((origin) => parsed.origin === origin.replace(/\/+$/, ""));
  } catch {
    return false;
  }
}

export function parseAllowedOrigins(raw: string | undefined, fallbackOrigin: string): string[] {
  const fromEnv = (raw ?? "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean)
    .map((entry) => {
      try {
        return new URL(entry).origin;
      } catch {
        return entry.replace(/\/+$/, "");
      }
    });
  const merged = new Set(fromEnv);
  merged.add(fallbackOrigin.replace(/\/+$/, ""));
  return [...merged];
}
