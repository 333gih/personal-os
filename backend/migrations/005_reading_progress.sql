-- Story Tracker reading progress (synced from browser extension)

CREATE TABLE IF NOT EXISTS reading_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    story_id VARCHAR(128) NOT NULL,
    story_title VARCHAR(500) NOT NULL,
    chapter_id VARCHAR(128),
    chapter_title VARCHAR(500),
    current_url TEXT NOT NULL DEFAULT '',
    progress_percentage INT NOT NULL DEFAULT 0,
    scroll_y INT NOT NULL DEFAULT 0,
    reading_time_seconds INT NOT NULL DEFAULT 0,
    site_id VARCHAR(64) NOT NULL DEFAULT 'generic',
    metadata JSONB NOT NULL DEFAULT '{}',
    client_timestamp TIMESTAMPTZ,
    last_read_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_reading_progress_user_story_chapter
    ON reading_progress (user_id, story_id, COALESCE(chapter_id, ''));

CREATE INDEX IF NOT EXISTS idx_reading_progress_user_last_read
    ON reading_progress (user_id, last_read_at DESC);
