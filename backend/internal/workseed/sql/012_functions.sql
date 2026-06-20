-- Resolve career / seed data owner for SQL migrations.
-- Owner must log in once (Fash Auth) so users row exists with the correct JWT user id.

CREATE SCHEMA IF NOT EXISTS personal_os;

CREATE OR REPLACE FUNCTION personal_os.career_owner_email()
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT 'mphuc8671@gmail.com'::TEXT;
$$;

CREATE OR REPLACE FUNCTION personal_os.resolve_career_owner_id()
RETURNS UUID
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    owner_email TEXT := personal_os.career_owner_email();
    uid UUID;
BEGIN
    SELECT id INTO uid
    FROM users
    WHERE lower(trim(email)) = lower(trim(owner_email))
    LIMIT 1;
    RETURN uid;
END;
$$;

COMMENT ON FUNCTION personal_os.career_owner_email IS 'Personal OS seed data owner (login account)';
COMMENT ON FUNCTION personal_os.resolve_career_owner_id IS 'UUID for career_owner_email; NULL until first login';
