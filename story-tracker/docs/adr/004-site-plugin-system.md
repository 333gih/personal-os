# ADR 004: Site plugin system

## Status

Accepted

## Context

Reading sites share the same goal (detect story, chapter, progress, sync) but differ in DOM and navigation:

- **Standard**: chapter in URL (`/chuong-26/`) or visible heading.
- **Special** (e.g. Vietnam Thu Quan): postback, `#muluben_to` acronym catalog, `noidung1()` — URL does not change.

We need one **core pipeline** with optional **site plugins** that preserve the same input/output (`ReadingInfo`).

## Decision

### Core pipeline (all sites)

1. Match `SiteProfile` (URL rules + selectors)
2. `crawlStoryMeta` + `crawlChapterMeta` → build `ReadingInfo` base
3. If `profile.extension.handler` is set → `applySitePlugin(base)` → enhanced `ReadingInfo`
4. Save session + sync to Personal OS

### Site plugins

- Location: `src/plugins/builtin/<id>/`
- Contract: `SitePlugin` in `src/plugins/types.ts`
  - **Input**: `SitePluginInput` (ctx, profile, extension, chapterMeta, base ReadingInfo)
  - **Output**: `ReadingInfo` (same shape always)
  - Optional: `resumeChapter(document, payload)` for postback readers

### Built-in plugins

| id | Site | Pre-linked profile |
|----|------|-------------------|
| `vietnamthuquan` | vietnamthuquan.eu | `site-profiles.json` → `extension.handler` |

### User custom sites

- **Level 1**: Custom profile — URL pattern + selectors only
- **Level 2**: Custom profile + `extension.handler` pointing to a built-in plugin id
- **Level 3**: New plugin request — email support with site DOM notes

Settings UI documents all three levels (`SITE_PLUGIN_GUIDE`).

## Consequences

- New special sites add a plugin under `plugins/builtin/` and register in `plugins/builtin/index.ts`
- Generic parsers unchanged for NetTruyen, TruyenFull, etc.
- Standalone `vietnamthuquan-extension` removed — single `story-tracker` extension
