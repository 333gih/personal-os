-- Align users.email unique constraint name with GORM model (users_email_key).
-- Safe to run on DBs created from older 001_initial_schema.sql (inline UNIQUE).

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'users_email_key' AND conrelid = 'users'::regclass
    ) THEN
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uni_users_email' AND conrelid = 'users'::regclass
    ) THEN
        ALTER TABLE users RENAME CONSTRAINT uni_users_email TO users_email_key;
        RETURN;
    END IF;

    -- Inline UNIQUE or unnamed constraint: add named constraint if email is unique.
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint c
        JOIN pg_class t ON c.conrelid = t.oid
        JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = ANY (c.conkey)
        WHERE t.relname = 'users' AND a.attname = 'email' AND c.contype = 'u'
    ) THEN
        ALTER TABLE users ADD CONSTRAINT users_email_key UNIQUE (email);
    END IF;
END $$;
