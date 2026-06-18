export function buildAdminPortalInternalLoginUrl(next = "/dashboard"): string {
  const adminLogin =
    process.env.NEXT_PUBLIC_ADMIN_PORTAL_URL?.trim() ||
    "https://fashandcurious.com/management/auth/login";
  const siteOrigin = (
    process.env.NEXT_PUBLIC_SITE_URL?.trim() ||
    (typeof window !== "undefined" ? window.location.origin : "http://localhost:3000")
  ).replace(/\/+$/, "");

  const callback = `${siteOrigin}/api/auth/internal/callback`;
  const url = new URL(adminLogin);
  url.searchParams.set("sso", "personal-os");
  url.searchParams.set("sso_return", callback);
  url.searchParams.set("sso_next", next.startsWith("/") ? next : "/dashboard");
  return url.toString();
}
