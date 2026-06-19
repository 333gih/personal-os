import { BUILTIN_SITE_PLUGINS } from './builtin';
import type { SitePlugin, SitePluginSummary } from './types';

const pluginMap = new Map<string, SitePlugin>(
  BUILTIN_SITE_PLUGINS.map((plugin) => [plugin.id, plugin]),
);

export function getSitePlugin(id?: string | null): SitePlugin | null {
  if (!id) return null;
  return pluginMap.get(id) ?? null;
}

export function listBuiltinPlugins(): SitePluginSummary[] {
  return BUILTIN_SITE_PLUGINS.map(({ id, label, description, builtin }) => ({
    id,
    label,
    description,
    builtin,
  }));
}

export function hasSitePlugin(id: string): boolean {
  return pluginMap.has(id);
}
