# ADR 003: Storage and Offline Sync Strategy

## Status

Accepted

## Context

Users read stories with intermittent connectivity. Reading progress must persist locally and sync reliably when the backend is reachable. The extension must not lose data on network failures.

## Decision

Use `browser.storage.local` as the single persistence layer with structured keys:

| Key | Purpose |
|-----|---------|
| `auth` | JWT tokens and user profile |
| `unsyncedEvents` | Offline queue of reading progress payloads |
| `parserCache` | Cached parser metadata per URL |
| `readingSessions` | Active reading sessions by story+chapter |
| `readingHistory` | Last 50 stories for popup display |
| `syncStatus` | Sync state, pending count, last error |
| `settings` | User preferences (sync interval, enabled sites) |

### Offline Queue

1. Failed or offline syncs enqueue `UnsyncedEvent` with UUID
2. Queue capped at 500 events (oldest dropped)
3. Background worker retries on:
   - Configurable interval (default 30s)
   - Tab unload / visibility loss (via content script)
   - Chapter change
   - Manual "Sync Now"
   - `online` event
4. Exponential backoff on API retries (1s base, max 5 attempts per request)

### Sync Rules

- **Never** send API requests on every scroll event
- Debounce content updates (2s)
- Throttle scroll handler (500ms)
- Batch queue flush in background

## Consequences

### Positive

- Works fully offline for reading tracking
- No data loss on transient failures
- User-visible pending count in popup
- Export capability for data portability

### Negative

- `storage.local` has ~10MB limit (sufficient for queue + history)
- No cross-device sync without backend
- Duplicate events possible if same progress queued multiple times (backend should upsert by storyId+chapterId)

### Risks

- Storage quota exceeded on very long offline periods → mitigated by 500-event cap
- Stale queue entries after story URL changes → mitigated by clientTimestamp on payloads

## Alternatives Considered

| Approach | Rejected Because |
|----------|------------------|
| IndexedDB | Overkill for small structured data |
| `storage.sync` | 100KB quota too small for queue |
| Service Worker Cache API | Wrong abstraction for structured state |
