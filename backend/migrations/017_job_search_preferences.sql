-- Job search preferences per user (LinkedIn-style filters for Job Scout)
-- psql $DATABASE_URL -f migrations/017_job_search_preferences.sql

CREATE TABLE IF NOT EXISTS job_search_preferences (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    focus_skills JSONB NOT NULL DEFAULT '[]'::jsonb,
    years_experience REAL NOT NULL DEFAULT 3,
    target_role TEXT NOT NULL DEFAULT '',
    work_location_types JSONB NOT NULL DEFAULT '["remote"]'::jsonb,
    employment_types JSONB NOT NULL DEFAULT '["full_time"]'::jsonb,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_job_search_preferences_updated ON job_search_preferences(updated_at DESC);
