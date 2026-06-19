export const SITE_PLUGIN_GUIDE = {
  title: 'How reading sites are tracked',
  levels: [
    {
      level: 1,
      title: 'Standard sites (most truyen sites)',
      body:
        'URL + DOM selectors only. Works for NetTruyen, TruyenFull, sites with /chuong-123/ in the path. Add a custom profile with URL pattern, path keywords, and optional selector JSON.',
    },
    {
      level: 2,
      title: 'Built-in site plugins (special readers)',
      body:
        'Some sites use postback / hidden chapter state (e.g. vietnamthuquan.eu). Attach a pre-installed plugin via extension.handler in the profile JSON. Output stays the same ReadingInfo — popup still shows chapter progress and sync works.',
    },
    {
      level: 3,
      title: 'Need a new plugin?',
      body:
        'If selectors + existing plugins are not enough, email support with: site URL example, how chapters are listed, how the current chapter is shown, and whether URL changes on chapter switch. We add a new builtin plugin with the same input/output contract.',
    },
  ],
  extensionExample: `{
  "handler": "vietnamthuquan",
  "displayFormat": "chapter_of_total",
  "cacheCatalog": true,
  "fields": {
    "storyTitle": "span.chuto40, .chuto40",
    "currentChapter": ".chuongso",
    "catalogRoot": "#muluben_to",
    "catalogItem": "acronym"
  }
}`,
  supportEmail: 'support@fashandcurious.com',
} as const;
