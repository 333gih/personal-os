export async function createStoryFingerprint(
  title: string,
  url: string,
  metadata?: Record<string, unknown>,
): Promise<string> {
  const host = new URL(url).hostname.replace(/^www\./, '');
  const payload = JSON.stringify({
    title: title.trim().toLowerCase(),
    host,
    meta: metadata ?? {},
  });

  const encoder = new TextEncoder();
  const data = encoder.encode(payload);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('').slice(0, 16);
}

export function createUrlHash(url: string): string {
  let hash = 0;
  const normalized = url.toLowerCase();
  for (let i = 0; i < normalized.length; i++) {
    hash = (hash << 5) - hash + normalized.charCodeAt(i);
    hash |= 0;
  }
  return Math.abs(hash).toString(36);
}
