import { getSitePlugin } from './registry';
import type { SitePluginInput } from './types';
import type { ReadingInfo } from '../types/reading';

/** Apply optional site plugin on top of generic core output. Same I/O: ReadingInfo. */
export async function applySitePlugin(input: SitePluginInput): Promise<ReadingInfo> {
  const handlerId = input.profile.extension?.handler;
  if (!handlerId) return input.base;

  const plugin = getSitePlugin(handlerId);
  if (!plugin) {
    return {
      ...input.base,
      metadata: {
        ...input.base.metadata,
        plugin_error: `unknown_plugin:${handlerId}`,
        plugin_hint: 'See Settings → Site plugins for built-in handler ids.',
      },
    };
  }

  return plugin.enhance(input);
}

export async function resumeWithSitePlugin(
  document: Document,
  info: ReadingInfo,
): Promise<boolean> {
  const pluginId = (info.metadata?.site_plugin ?? info.metadata?.site_handler) as string | undefined;
  const plugin = getSitePlugin(pluginId);
  const chapterNumber = String(info.metadata?.chapter_number ?? '').trim();
  if (!plugin?.resumeChapter || !chapterNumber) return false;

  return plugin.resumeChapter(document, {
    chapterNumber,
    chuongid: info.metadata?.chuongid ? String(info.metadata.chuongid) : undefined,
    tuaid: info.metadata?.tuaid ? String(info.metadata.tuaid) : undefined,
  });
}
