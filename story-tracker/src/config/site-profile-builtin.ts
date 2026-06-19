import type { CustomSiteProfile, SiteProfile, SiteProfileRegistry } from '../types/site-profile';
import profilesJson from './site-profiles.json';

const builtinRegistry = profilesJson as SiteProfileRegistry;

export function getBuiltinProfiles(): SiteProfile[] {
  return builtinRegistry.profiles
    .filter((p) => p.enabled)
    .sort((a, b) => (b.priority ?? 0) - (a.priority ?? 0));
}

export function getBuiltinProfileById(id: string): SiteProfile | undefined {
  return builtinRegistry.profiles.find((p) => p.id === id);
}

export function customProfileToSiteProfile(profile: CustomSiteProfile): SiteProfile {
  const hostPatterns = profile.urlRules.hostPatterns?.length
    ? profile.urlRules.hostPatterns
    : [profile.originPattern];

  return {
    ...profile,
    urlRules: {
      ...profile.urlRules,
      hostPatterns,
    },
  };
}

export function listBuiltinHostPatterns(): string[] {
  const patterns = new Set<string>();
  for (const profile of getBuiltinProfiles()) {
    for (const pattern of profile.urlRules.hostPatterns ?? []) {
      patterns.add(pattern);
    }
  }
  return [...patterns];
}

export function matchProfile(url: string, profiles: SiteProfile[]): SiteProfile | null {
  const sorted = [...profiles].sort((a, b) => (b.priority ?? 0) - (a.priority ?? 0));
  for (const profile of sorted) {
    if (profileMatchesUrl(url, profile)) return profile;
  }
  return null;
}

export function profileMatchesUrl(url: string, profile: SiteProfile): boolean {
  try {
    const parsed = new URL(url);
    const hostPatterns = profile.urlRules.hostPatterns ?? [];
    const hostOk =
      hostPatterns.length === 0 ||
      hostPatterns.some((pattern) => hostPatternMatches(pattern, parsed.href, parsed.hostname));

    if (!hostOk) return false;

    const pathBlob = `${parsed.pathname}${parsed.search}`.toLowerCase();
    const pathKeywords = profile.urlRules.pathKeywords ?? [];
    const hostKeywords = profile.urlRules.hostKeywords ?? [];

    if (hostPatterns.length === 0) {
      const pathHit =
        pathKeywords.length === 0 ||
        pathKeywords.some((kw) => pathBlob.includes(kw.toLowerCase()));
      const hostHit =
        hostKeywords.length === 0 ||
        hostKeywords.some((kw) => parsed.hostname.toLowerCase().includes(kw.toLowerCase()));
      if (!pathHit && !hostHit) return false;
    } else if (pathKeywords.length > 0) {
      const keywordOk = pathKeywords.some((kw) => pathBlob.includes(kw.toLowerCase()));
      if (!keywordOk) return false;
    }

    if (profile.urlRules.pathRegex) {
      const re = new RegExp(profile.urlRules.pathRegex, 'i');
      if (!re.test(parsed.pathname)) return false;
    }

    return true;
  } catch {
    return false;
  }
}

function hostPatternMatches(pattern: string, url: string, hostname: string): boolean {
  if (pattern === '*://*/*') return true;
  const escaped = pattern.replace(/[.+?^${}()|[\]\\]/g, '\\$&').replace(/\*/g, '.*');
  return (
    new RegExp(`^${escaped}$`, 'i').test(url) ||
    hostname.toLowerCase().includes(patternToHost(pattern).toLowerCase())
  );
}

function patternToHost(pattern: string): string {
  const match = pattern.match(/\/\/(?:\*\.)?([^/*]+)/);
  return match?.[1]?.replace(/^\*\./, '') ?? '';
}
