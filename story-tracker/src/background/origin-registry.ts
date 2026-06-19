import browser from 'webextension-polyfill';
import { isChapterPage } from '../parsers/page-classifier';
import { listBuiltinHostPatterns } from '../config/site-profile-builtin';
import { getBuiltinProfiles, customProfileToSiteProfile } from '../config/site-profile-store';
import { platformCapabilities } from '../platform/capabilities';
import { storageService } from '../storage/storage-service';
import { logger } from '../utils/logger';

const CONTENT_SCRIPT_ID_PREFIX = 'story-tracker-origin-';

export async function registerKnownContentScripts(): Promise<void> {
  if (!platformCapabilities.dynamicContentScripts) return;

  const settings = await storageService.getSettings();
  const patterns = [
    ...listBuiltinHostPatterns(),
    ...settings.customProfiles.map((p) => p.originPattern),
    ...settings.customOrigins.map((origin) => origin.pattern),
  ];

  for (const pattern of patterns) {
    await registerPatternIfPermitted(pattern);
  }
}

export async function maybeDiscoverOrigin(url: string): Promise<void> {
  const settings = await storageService.getSettings();
  const profiles = [
    ...settings.customProfiles.map(customProfileToSiteProfile),
    ...getBuiltinProfiles(),
  ];
  if (!settings.autoDiscoverSites || !isChapterPage(url, profiles)) return;

  let origin = '';
  try {
    origin = new URL(url).origin;
  } catch {
    return;
  }

  const pattern = `${origin}/*`;
  const exists = settings.customOrigins.some((item) => item.pattern === pattern);
  if (!exists) {
    await storageService.update('settings', (current) => ({
      ...current,
      customOrigins: [
        ...current.customOrigins,
        { pattern, label: new URL(url).hostname, addedAt: Date.now() },
      ],
    }));
  }

  if (platformCapabilities.dynamicContentScripts) {
    await registerPatternIfPermitted(pattern);
  }
}

async function registerPatternIfPermitted(pattern: string): Promise<void> {
  if (!platformCapabilities.dynamicContentScripts) return;
  const id = `${CONTENT_SCRIPT_ID_PREFIX}${pattern.replace(/[^a-z0-9]+/gi, '-')}`;
  const hasPermission = await browser.permissions.contains({ origins: [pattern] });
  if (!hasPermission) {
    try {
      const granted = await browser.permissions.request({ origins: [pattern] });
      if (!granted) return;
    } catch {
      return;
    }
  }

  try {
    const registered = await browser.scripting.getRegisteredContentScripts({ ids: [id] });
    if (registered.length > 0) return;

    await browser.scripting.registerContentScripts([
      {
        id,
        matches: [pattern],
        js: ['src/content/index.js'],
        runAt: 'document_idle',
        persistAcrossSessions: true,
      },
    ]);
    logger.info('Registered dynamic content script for', pattern);
  } catch (error) {
    logger.warn('Could not register content script', pattern, error);
  }
}
