-- Daily Job Scout schedule + push preferences
-- psql $DATABASE_URL -f migrations/033_job_scout_daily_schedule.sql

ALTER TABLE job_search_preferences
    ADD COLUMN IF NOT EXISTS daily_scan_enabled BOOLEAN NOT NULL DEFAULT true,
    ADD COLUMN IF NOT EXISTS push_enabled BOOLEAN NOT NULL DEFAULT true,
    ADD COLUMN IF NOT EXISTS timezone TEXT NOT NULL DEFAULT 'Asia/Ho_Chi_Minh',
    ADD COLUMN IF NOT EXISTS last_scan_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_job_search_preferences_daily
    ON job_search_preferences(daily_scan_enabled, last_scan_at DESC);
