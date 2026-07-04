-- Calendar sync event mapping (reminder/job -> external calendar event id)
CREATE TABLE IF NOT EXISTS calendar_sync_events (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    source_kind       VARCHAR(64) NOT NULL,
    source_id         UUID NOT NULL,
    provider          VARCHAR(32) NOT NULL DEFAULT 'google',
    external_event_id VARCHAR(256) NOT NULL,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, source_kind, source_id, provider)
);

CREATE INDEX IF NOT EXISTS idx_calendar_sync_events_user ON calendar_sync_events(user_id);
