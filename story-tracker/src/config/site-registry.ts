import type { SiteRegistry } from '../types/site-registry';
import registryJson from './site-registry.json';

const builtinRegistry = registryJson as SiteRegistry;

export function getBuiltinSiteRegistry(): SiteRegistry {
  return builtinRegistry;
}

export function listBuiltinHostPatterns(): string[] {
  const patterns = new Set<string>();
  for (const site of builtinRegistry.sites) {
    for (const pattern of site.hostPatterns) {
      patterns.add(pattern);
    }
  }
  return [...patterns];
}

export function findSiteByUrl(url: string): SiteRegistry['sites'][number] | null {
  try {
    const hostname = new URL(url).hostname;
    for (const site of builtinRegistry.sites) {
      if (site.hostPatterns.some((pattern) => hostPatternMatches(pattern, hostname, url))) {
        return site;
      }
    }
  } catch {
    return null;
  }
  return null;
}

function hostPatternMatches(pattern: string, hostname: string, url: string): boolean {
  const escaped = pattern
    .replace(/[.+?^${}()|[\]\\]/g, '\\$&')
    .replace(/\*/g, '.*');
  return new RegExp(`^${escaped}$`, 'i').test(url) || hostname.includes(patternToHost(pattern));
}

function patternToHost(pattern: string): string {
  const match = pattern.match(/\/\/(?:\*\.)?([^/*]+)/);
  return match?.[1]?.replace(/^\*\./, '') ?? '';
}
