# ADR 003: Site Profile System (configurable URL + DOM detection)

## Status

Accepted

## Context

Reading sites use many URL shapes (`/chuong-26`, `truyen.aspx?tid=`, hash-only chapters) and
dynamic UIs (chapter list in sidebar, SPA without URL updates). Hard-coded parsers per domain do
not scale; Vietnam Thu Quan `.eu` is a concrete example where URL does not reflect the active
chapter.

## Decision

Introduce **Site Profiles** — declarative config per site (builtin JSON + user settings):

| Layer | Role |
|-------|------|
| `site-profiles.json` | Builtin profiles (VTQ, NetTruyen, generic-vi-auto, …) |
| `url-detector.ts` | Path/host keywords: truyen, chuong, thuvien, thuquan, … |
| `page-classifier.ts` | Chapter vs listing using profiles + keywords |
| `dom-crawler.ts` | Extract story/chapter from DOM (active sidebar, visible heading) |
| `profile-parser.ts` | Unified parser driven by profile strategies |
| `chapter-observer.ts` | MutationObserver + click debounce for dynamic chapter changes |
| Settings → `customProfiles` | User adds URL pattern, keywords, optional selectors JSON |

### Chapter detection strategies (ordered per profile)

1. `url_query` — e.g. `?tid=`
2. `url_hash` — e.g. `#phandau`
3. `url_path` — e.g. `/chuong-26`
4. `dom_active` — highlighted item in chapter list / menu
5. `dom_visible` — heading nearest viewport while scrolling
6. `title_split` — `document.title` separators

### Auto-discover

When `autoDiscoverSites` is on and URL matches reading keywords, extension requests host
permission and registers content script (unchanged flow, broader classification).

## Consequences

### Positive

- New domains often work via keywords without code change
- VTQ-style SPAs sync on sidebar click, not only URL change
- Power users tune selectors in Settings without shipping a build

### Negative

- More moving parts than single parser class per site
- Generic keyword match may false-positive on non-reading `/truyen/` admin pages (mitigated by listing exclusions)

## Files

```
src/types/site-profile.ts
src/config/site-profiles.json
src/config/site-profile-store.ts
src/parsers/url-detector.ts
src/parsers/dom-crawler.ts
src/parsers/profile-parser.ts
src/content/chapter-observer.ts
```
