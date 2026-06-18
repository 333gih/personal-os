# ADR 001: Plugin-Based Parser System

## Status

Accepted

## Context

Story Tracker must support hundreds of novel, manga, and story websites with varying URL structures, DOM layouts, and levels of chapter metadata. A monolithic scraping approach would not scale and would create high maintenance burden.

## Decision

Implement a **plugin-based parser architecture** with:

1. A `StoryParser` interface (`canHandle`, `extract`)
2. Site-specific parsers (NetTruyen, TruyenQQ, VietnamThuQuan) with high priority
3. A `GenericParser` fallback with multi-strategy extraction
4. A `ParserFactoryRegistry` that resolves parsers by priority and URL match

### Extraction Priority (GenericParser)

1. URL metadata (slug patterns, chapter numbers)
2. DOM selectors (site-agnostic common patterns)
3. Breadcrumbs
4. Previous/next chapter navigation
5. `document.title` parsing
6. Scroll percentage fallback

### Sites Without Chapter Metadata

When chapter info is unavailable, progress is keyed by:

- **Story fingerprint** — SHA-256 hash of normalized title + host
- **URL hash** — deterministic hash of normalized URL
- **Scroll percentage** — reading position within page

## Consequences

### Positive

- New sites added by implementing one parser class and registering it
- Generic parser handles unknown sites without blocking usage
- Selectors live only inside parser classes (no global pollution)
- Priority system allows overlapping URL patterns

### Negative

- Site-specific parsers require maintenance when sites redesign
- Generic parser accuracy is lower than dedicated parsers
- Content scripts only run on configured host permissions (not all URLs)

### Risks

- DOM changes on popular sites break extraction → mitigated by multi-strategy fallback
- Fingerprint collisions on similarly titled stories → mitigated by host scoping

## Alternatives Considered

| Approach | Rejected Because |
|----------|------------------|
| URL-only parsing | Fails on dynamic/opaque URLs |
| Single mega-parser with config JSON | Hard to test, poor separation of concerns |
| AI-based extraction | Latency, cost, privacy concerns |
