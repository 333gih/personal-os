-- Rename PostgreSQL default unique constraint to GORM's expected name (uni_users_email).
-- Safe to run on every deploy (idempotent).

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'uni_users_email' AND conrelid = 'users'::regclass
    ) THEN
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'users_email_key' AND conrelid = 'users'::regclass
    ) THEN
        ALTER TABLE users RENAME CONSTRAINT users_email_key TO uni_users_email;
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint c
        JOIN pg_class t ON c.conrelid = t.oid
        JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = ANY (c.conkey)
        WHERE t.relname = 'users' AND a.attname = 'email' AND c.contype = 'u'
    ) THEN
        ALTER TABLE users ADD CONSTRAINT uni_users_email UNIQUE (email);
    END IF;
END $$;
