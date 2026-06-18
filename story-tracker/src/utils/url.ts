export function normalizeUrl(url: string): string {
  try {
    const parsed = new URL(url);
    parsed.hash = '';
    return parsed.toString().replace(/\/$/, '');
  } catch {
    return url;
  }
}

export function getHostname(url: string): string {
  try {
    return new URL(url).hostname.replace(/^www\./, '');
  } catch {
    return '';
  }
}

export function matchesHostPattern(url: string, pattern: string): boolean {
  try {
    const { hostname } = new URL(url);
    const normalizedHost = hostname.replace(/^www\./, '');

    if (pattern.startsWith('*://')) {
      const rest = pattern.slice(4);
      const [hostPart, pathPart] = rest.split('/', 1).length === 1
        ? [rest.replace('/*', ''), '/*']
        : [rest.split('/')[0], '/' + rest.split('/').slice(1).join('/')];

      const hostPattern = hostPart.replace(/^\*\./, '');
      const hostMatch =
        hostPart.startsWith('*.') ?
          normalizedHost === hostPattern || normalizedHost.endsWith('.' + hostPattern)
        : normalizedHost === hostPart;

      if (!hostMatch) return false;
      if (pathPart === '/*' || pathPart === '') return true;
      return new URL(url).pathname.startsWith(pathPart.replace('/*', ''));
    }

    return url.startsWith(pattern);
  } catch {
    return false;
  }
}
