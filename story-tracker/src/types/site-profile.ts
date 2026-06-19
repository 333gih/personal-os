/** How to identify the active chapter when URL/hash is unreliable (SPA readers). */
export type ChapterDetectionStrategy =
  | 'url_path'
  | 'url_query'
  | 'url_hash'
  | 'dom_toc'
  | 'dom_chuongso'
  | 'dom_select'
  | 'dom_click_hint'
  | 'dom_content_heading'
  | 'dom_active'
  | 'dom_visible'
  | 'title_split';

export type SiteProfileSelectors = {
  storyTitle?: string[];
  chapterTitle?: string[];
  chapterList?: string[];
  chapterListItem?: string[];
  chapterActive?: string[];
  /** Mục lục / table of contents block (Vietnam Thu Quan, SPA readers). */
  tableOfContents?: string[];
  contentRoot?: string[];
};

export type SiteProfileUrlRules = {
  /** Match patterns like *://*.vietnamthuquan.eu/* */
  hostPatterns?: string[];
  /** Match if pathname/search contains any keyword (truyen, thuvien, …). */
  pathKeywords?: string[];
  /** Hostname contains keyword (thuquan, truyen, …). */
  hostKeywords?: string[];
  /** Optional path regex (without flags). */
  pathRegex?: string;
  queryParams?: {
    story?: string;
    chapter?: string;
  };
};

export type SiteProfileExtension = {
  /** Built-in site handler id (e.g. vietnamthuquan). */
  handler?: string;
  /** Popup display style. */
  displayFormat?: 'chapter_of_total' | 'default';
  /** Cache total chapter count after first successful scan. */
  cacheCatalog?: boolean;
  /** Contact when custom selectors cannot adapt. */
  supportContact?: string;
  /** Optional override selectors for extension handler. */
  fields?: {
    storyTitle?: string;
    currentChapter?: string;
    catalogRoot?: string;
    catalogItem?: string;
  };
};

export type SiteProfile = {
  id: string;
  label: string;
  enabled: boolean;
  builtin?: boolean;
  priority?: number;
  urlRules: SiteProfileUrlRules;
  chapterDetection: ChapterDetectionStrategy[];
  selectors: SiteProfileSelectors;
  /** Site-specific behavior on top of the generic parser core. */
  extension?: SiteProfileExtension;
  addedAt?: number;
};

export type SiteProfileRegistry = {
  profiles: SiteProfile[];
};

/** User-defined profile stored in extension settings. */
export type CustomSiteProfile = SiteProfile & {
  builtin?: false;
  originPattern: string;
};

export type DomChapterResult = {
  chapterId?: string;
  chapterTitle?: string;
  /** Deep link URL (query + hash) for reopening this chapter. */
  chapterUrl?: string;
  partId?: string;
  partTitle?: string;
  source?: string;
  totalChapters?: number;
  chapterIndex?: number;
};

export type DomStoryResult = {
  storyId?: string;
  storyTitle?: string;
  source?: string;
};
