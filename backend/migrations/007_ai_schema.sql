-- AI infrastructure schema (additive — does not alter public.entities contract)
-- Requires PostgreSQL 17 + pgvector (existing)

CREATE SCHEMA IF NOT EXISTS ai;
CREATE SCHEMA IF NOT EXISTS audit;

-- Async embedding job queue (replaces fire-and-forget goroutines)
CREATE TABLE IF NOT EXISTS ai.embedding_jobs (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    source_table VARCHAR(50) NOT NULL,  -- entities | reading_progress
    entity_type  VARCHAR(50) NOT NULL, -- TASK, LEARNING, STARTUP, BOOK, GOAL, JOURNAL
    entity_id    UUID NOT NULL,
    status       VARCHAR(20) NOT NULL DEFAULT 'pending',
    attempts     INT NOT NULL DEFAULT 0,
    last_error   TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMPTZ,
    CONSTRAINT uni_embedding_jobs_source UNIQUE (source_table, entity_id)
);

CREATE INDEX IF NOT EXISTS idx_embedding_jobs_status ON ai.embedding_jobs(status, created_at);
CREATE INDEX IF NOT EXISTS idx_embedding_jobs_user ON ai.embedding_jobs(user_id);

-- AI interaction audit trail
CREATE TABLE IF NOT EXISTS ai.ai_interactions (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    endpoint   VARCHAR(50) NOT NULL DEFAULT 'chat',
    model      VARCHAR(100),
    tokens_in  INT NOT NULL DEFAULT 0,
    tokens_out INT NOT NULL DEFAULT 0,
    latency_ms INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_interactions_user ON ai.ai_interactions(user_id, created_at DESC);

-- Prompt templates (managed by AI module)
CREATE TABLE IF NOT EXISTS ai.prompt_templates (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name       VARCHAR(100) NOT NULL,
    version    INT NOT NULL DEFAULT 1,
    template   TEXT NOT NULL,
    is_active  BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uni_prompt_templates_name_version UNIQUE (name, version)
);

-- User feedback on AI responses
CREATE TABLE IF NOT EXISTS ai.ai_feedback (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    interaction_id UUID REFERENCES ai.ai_interactions(id) ON DELETE SET NULL,
    user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating         SMALLINT,
    comment        TEXT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Per-user model usage and cost tracking
CREATE TABLE IF NOT EXISTS ai.model_usage (
    user_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    model    VARCHAR(100) NOT NULL,
    date     DATE NOT NULL DEFAULT CURRENT_DATE,
    tokens   BIGINT NOT NULL DEFAULT 0,
    cost_usd NUMERIC(10, 6) NOT NULL DEFAULT 0,
    PRIMARY KEY (user_id, model, date)
);

-- Unified searchable projection for embedding worker (entities + reading_progress)
CREATE OR REPLACE VIEW ai.searchable_content AS
SELECT
    e.id,
    e.user_id,
    CASE e.domain
        WHEN 'learning' THEN 'LEARNING'
        WHEN 'startup'  THEN 'STARTUP'
        WHEN 'goal'     THEN 'GOAL'
        WHEN 'journal'  THEN 'JOURNAL'
        WHEN 'work'     THEN 'TASK'
        ELSE 'TASK'
    END AS entity_type,
    'entities'::VARCHAR(50) AS source_table,
    e.title,
    e.content,
    e.tags,
    e.metadata,
    e.created_at,
    e.updated_at
FROM entities e
WHERE e.status = 'active'
UNION ALL
SELECT
    rp.id,
    rp.user_id,
    'BOOK'::VARCHAR(50) AS entity_type,
    'reading_progress'::VARCHAR(50) AS source_table,
    rp.story_title AS title,
    TRIM(BOTH FROM COALESCE(rp.chapter_title, '') || E'\n' || COALESCE(rp.current_url, '')) AS content,
    '[]'::JSONB AS tags,
    rp.metadata,
    rp.created_at,
    rp.updated_at
FROM reading_progress rp;

-- Backfill embedding jobs for existing content (idempotent)
INSERT INTO ai.embedding_jobs (user_id, source_table, entity_type, entity_id, status)
SELECT
    e.user_id,
    'entities',
    CASE e.domain
        WHEN 'learning' THEN 'LEARNING'
        WHEN 'startup'  THEN 'STARTUP'
        WHEN 'goal'     THEN 'GOAL'
        WHEN 'journal'  THEN 'JOURNAL'
        WHEN 'work'     THEN 'TASK'
        ELSE 'TASK'
    END,
    e.id,
    'pending'
FROM entities e
WHERE e.status = 'active'
ON CONFLICT (source_table, entity_id) DO NOTHING;

INSERT INTO ai.embedding_jobs (user_id, source_table, entity_type, entity_id, status)
SELECT rp.user_id, 'reading_progress', 'BOOK', rp.id, 'pending'
FROM reading_progress rp
ON CONFLICT (source_table, entity_id) DO NOTHING;
