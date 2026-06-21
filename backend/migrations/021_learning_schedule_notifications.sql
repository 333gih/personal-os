-- Learning schedule, study jobs, notification logs, reminder extensions
-- psql $DATABASE_URL -f migrations/021_learning_schedule_notifications.sql

ALTER TABLE reminders
    ADD COLUMN IF NOT EXISTS kind VARCHAR(64) DEFAULT 'general',
    ADD COLUMN IF NOT EXISTS notified_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;

CREATE INDEX IF NOT EXISTS idx_reminders_pending_due
    ON reminders(user_id, due_at)
    WHERE status = 'pending' AND notified_at IS NULL;

CREATE TABLE IF NOT EXISTS learning_schedules (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    work_start_hour INT NOT NULL DEFAULT 8,
    work_end_hour INT NOT NULL DEFAULT 17,
    work_days JSONB NOT NULL DEFAULT '[1,2,3,4,5]',
    commute_minutes INT NOT NULL DEFAULT 40,
    morning_commute_time TIME NOT NULL DEFAULT '07:15',
    evening_commute_time TIME NOT NULL DEFAULT '17:30',
    toeic_session_time TIME NOT NULL DEFAULT '20:00',
    dsa_commute_minutes INT NOT NULL DEFAULT 25,
    english_commute_minutes INT NOT NULL DEFAULT 20,
    toeic_daily_minutes INT NOT NULL DEFAULT 60,
    timezone VARCHAR(64) NOT NULL DEFAULT 'Asia/Ho_Chi_Minh',
    push_enabled BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS study_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    kind VARCHAR(64) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'pending',
    input JSONB NOT NULL DEFAULT '{}'::jsonb,
    result JSONB,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_study_jobs_user_status ON study_jobs(user_id, status);

CREATE TABLE IF NOT EXISTS notification_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    channel VARCHAR(32) NOT NULL DEFAULT 'push',
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'queued',
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    idempotency_key VARCHAR(255),
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notification_logs_user ON notification_logs(user_id, created_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS idx_notification_logs_idempotency
    ON notification_logs(user_id, idempotency_key)
    WHERE idempotency_key IS NOT NULL AND idempotency_key <> '';

-- Default schedule for career owner
DO $$
DECLARE
    admin_id UUID;
    owner_email TEXT := 'mphuc8671@gmail.com';
    dsa_course_id UUID := 'c000000c-0001-4001-8001-000000000001'::uuid;
BEGIN
    SELECT id INTO admin_id FROM users
    WHERE lower(trim(email)) = lower(trim(owner_email))
    LIMIT 1;

    IF admin_id IS NULL THEN
        RAISE NOTICE 'Owner % not found — skip default learning schedule', owner_email;
        RETURN;
    END IF;

    INSERT INTO learning_schedules (user_id)
    VALUES (admin_id)
    ON CONFLICT (user_id) DO NOTHING;

    -- Enhance TOEIC English course metadata
    UPDATE entities
    SET metadata = metadata || '{"toeic_mode":"hardcore","focus":"vocabulary,grammar,listening,reading","daily_target_minutes":60}'::jsonb,
        content = 'Hardcore TOEIC prep: daily vocabulary drills (business + academic), grammar traps, listening part 1–4 patterns, and reading inference. Optimized for metro/bus micro-sessions and evening deep study.',
        updated_at = NOW()
    WHERE id = 'c000000c-0001-4001-8001-000000000005'::uuid
      AND user_id = admin_id;

    RAISE NOTICE 'Learning schedule defaults applied for %', owner_email;
END $$;
