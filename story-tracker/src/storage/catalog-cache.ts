import { storageService } from './storage-service';
import { STORAGE_KEYS } from '../types/storage';

type CatalogCacheData = {
  totalChapters: number;
  cachedAt: number;
};

export async function getCatalogTotal(siteId: string, storyKey: string): Promise<number | null> {
  const cache = await storageService.get(STORAGE_KEYS.PARSER_CACHE);
  const entry = cache[`catalog:${siteId}:${storyKey}`];
  const data = entry?.data as CatalogCacheData | undefined;
  return data?.totalChapters ?? null;
}

export async function setCatalogTotal(
  siteId: string,
  storyKey: string,
  totalChapters: number,
): Promise<void> {
  await storageService.update(STORAGE_KEYS.PARSER_CACHE, (cache) => ({
    ...cache,
    [`catalog:${siteId}:${storyKey}`]: {
      siteId,
      lastUrl: '',
      cachedAt: Date.now(),
      data: { totalChapters, cachedAt: Date.now() },
    },
  }));
}
