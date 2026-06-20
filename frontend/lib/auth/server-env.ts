import "server-only";

function readEnv(name: string): string | undefined {
  const v = process.env[name];
  if (v === undefined || v === "") return undefined;
  return v;
}

export function getCookieSecureFromHeaders(headers: Headers): boolean {
  const explicit = readEnv("AUTH_COOKIE_SECURE");
  if (explicit === "true") return true;
  if (explicit === "false") return false;
  const xf = headers.get("x-forwarded-proto");
  if (xf) {
    const p = xf.split(",")[0].trim().toLowerCase();
    if (p === "http") return false;
    if (p === "https") return true;
  }
  return process.env.NODE_ENV === "production";
}

export type ServerAuthEnv = {
  API_URL: string;
  APPLICATION_ID: string;
  INTERNAL_APPLICATION_ID?: string;
  COMMERCIAL_APPLICATION_ID?: string;
  AUTH_LOCALE: string;
  PERSONAL_OS_API_URL: string;
  /** Docker-internal API (http://personal-os-api:8080) for server BFF — bypasses Kong. */
  PERSONAL_OS_API_INTERNAL_URL?: string;
  ADMIN_PORTAL_URL: string;
  INTERNAL_DEFAULT_USER_EMAIL?: string;
  INTERNAL_DEFAULT_USER_PASSWORD?: string;
  internalDefaultLoginEnabled: boolean;
  cookieSecure: boolean;
};

let cached: ServerAuthEnv | null = null;

export function getServerAuthEnv(): ServerAuthEnv {
  if (cached) return cached;

  const API_URL = readEnv("API_URL");
  const APPLICATION_ID = readEnv("NEXT_PUBLIC_APP_ID");
  const PERSONAL_OS_API_URL = readEnv("PERSONAL_OS_API_URL");

  if (!API_URL) {
    throw new Error(
      "Missing API_URL (fash-auth-service mount, e.g. https://api-auth.fashandcurious.com)",
    );
  }
  if (!APPLICATION_ID) {
    throw new Error("Missing NEXT_PUBLIC_APP_ID (must be allowed by fash-auth-service)");
  }
  if (!PERSONAL_OS_API_URL) {
    throw new Error(
      "Missing PERSONAL_OS_API_URL (e.g. https://api-personal-os.fashandcurious.com)",
    );
  }

  cached = {
    API_URL: API_URL.replace(/\/+$/, ""),
    APPLICATION_ID: APPLICATION_ID.trim(),
    INTERNAL_APPLICATION_ID: readEnv("INTERNAL_APPLICATION_ID")?.trim(),
    COMMERCIAL_APPLICATION_ID: readEnv("COMMERCIAL_APPLICATION_ID")?.trim(),
    AUTH_LOCALE: (readEnv("AUTH_LOCALE") || "vi").trim(),
    PERSONAL_OS_API_URL: PERSONAL_OS_API_URL.replace(/\/+$/, ""),
    PERSONAL_OS_API_INTERNAL_URL: readEnv("PERSONAL_OS_API_INTERNAL_URL")?.replace(/\/+$/, ""),
    ADMIN_PORTAL_URL: (
      readEnv("NEXT_PUBLIC_ADMIN_PORTAL_URL") ||
      readEnv("ADMIN_PORTAL_URL") ||
      "https://fashandcurious.com/management/auth/login"
    ).replace(/\/+$/, ""),
    INTERNAL_DEFAULT_USER_EMAIL: readEnv("INTERNAL_DEFAULT_USER_EMAIL")?.trim(),
    INTERNAL_DEFAULT_USER_PASSWORD: readEnv("INTERNAL_DEFAULT_USER_PASSWORD"),
    internalDefaultLoginEnabled: readEnv("INTERNAL_DEFAULT_LOGIN_ENABLED") === "true",
    cookieSecure:
      readEnv("AUTH_COOKIE_SECURE") === "true" ||
      (readEnv("AUTH_COOKIE_SECURE") !== "false" && process.env.NODE_ENV === "production"),
  };
  return cached;
}
