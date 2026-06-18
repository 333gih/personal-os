import { getSiteBaseUrl, normalizeSiteOrigin } from "@/lib/site-url";

function isInternalBindHost(host: string): boolean {
  const h = host.split(":")[0]?.toLowerCase() ?? "";
  return h === "0.0.0.0" || h === "127.0.0.1" || h === "localhost" || h === "::" || h === "[::]";
}

/**
 * Browser-facing origin behind Traefik or local dev.
 * Next standalone binds HOSTNAME=0.0.0.0 — `new URL(request.url).origin` is wrong for redirects.
 */
export function getPublicOriginFromHeaders(headers: Headers): string {
  const xfHost = headers.get("x-forwarded-host")?.split(",")[0]?.trim();
  const host = headers.get("host")?.split(",")[0]?.trim();
  const xfProto = headers.get("x-forwarded-proto")?.split(",")[0]?.trim();
  const chosenHost = xfHost || host;

  if (chosenHost && !isInternalBindHost(chosenHost)) {
    const proto =
      xfProto === "https" || xfProto === "http"
        ? xfProto
        : chosenHost.includes("localhost") || chosenHost.startsWith("127.")
          ? "http"
          : "https";
    return normalizeSiteOrigin(`${proto}://${chosenHost}`);
  }

  return getSiteBaseUrl();
}

export function absolutePublicUrl(headers: Headers, internalPath: string): URL {
  const path = internalPath.startsWith("/") ? internalPath : `/${internalPath}`;
  return new URL(path, getPublicOriginFromHeaders(headers));
}
