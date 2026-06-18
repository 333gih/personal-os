export type SiteRegistryEntry = {
  id: string;
  label: string;
  hostPatterns: string[];
  parser: string;
};

export type SiteRegistry = {
  sites: SiteRegistryEntry[];
};

export type CustomOrigin = {
  pattern: string;
  label: string;
  addedAt: number;
};
