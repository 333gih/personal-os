-- Job opportunities scouted from Remotive + GitHub (skill-matched)
CREATE TABLE IF NOT EXISTS job_opportunities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    source VARCHAR(50) NOT NULL,
    external_id VARCHAR(200) NOT NULL,
    title TEXT NOT NULL,
    company VARCHAR(200) DEFAULT '',
    location VARCHAR(200) DEFAULT '',
    url TEXT NOT NULL,
    description TEXT DEFAULT '',
    skills JSONB DEFAULT '[]'::jsonb,
    match_score REAL DEFAULT 0,
    match_reason TEXT DEFAULT '',
    posted_at TIMESTAMPTZ,
    scraped_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status VARCHAR(20) NOT NULL DEFAULT 'open',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, source, external_id)
);

CREATE INDEX IF NOT EXISTS idx_job_opportunities_user_score
    ON job_opportunities (user_id, match_score DESC, scraped_at DESC);

CREATE INDEX IF NOT EXISTS idx_job_opportunities_user_status
    ON job_opportunities (user_id, status);
