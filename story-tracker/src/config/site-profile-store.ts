import type { SiteProfile } from '../types/site-profile';
import {
  customProfileToSiteProfile,
  getBuiltinProfiles,
} from './site-profile-builtin';
import { storageService } from '../storage/storage-service';

export * from './site-profile-builtin';

export async function getActiveProfiles(): Promise<SiteProfile[]> {
  const settings = await storageService.getSettings();
  const custom = (settings.customProfiles ?? []).filter((p) => p.enabled);
  const builtin = getBuiltinProfiles();

  return [...custom.map(customProfileToSiteProfile), ...builtin].sort(
    (a, b) => (b.priority ?? 0) - (a.priority ?? 0),
  );
}
