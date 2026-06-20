-- Assign all seed/career data to mphuc8671@gmail.com (Fash Auth login account).
-- Safe to re-run after login if Work tab was empty.
-- psql $DATABASE_URL -f migrations/011_work_career_assign_user.sql

DO $$
DECLARE
    target_user UUID;
    target_email TEXT := 'mphuc8671@gmail.com';
    career_count INT;
    moved INT;
BEGIN
    SELECT id, email INTO target_user, target_email
    FROM users
    WHERE lower(trim(email)) = lower(trim(target_email))
    LIMIT 1;

    IF target_user IS NULL THEN
        RAISE EXCEPTION
            'User % not found. Log in to Personal OS (web or iOS) with this account first — Fash Auth creates the user row with your JWT id. Then re-run this file.',
            target_email;
    END IF;

    SELECT COUNT(*) INTO career_count FROM entities WHERE source = 'career_seed';

    IF career_count = 0 THEN
        RAISE EXCEPTION 'No career_seed data. Run: psql $DATABASE_URL -f migrations/010_work_career_all.sql';
    END IF;

    UPDATE entities
    SET user_id = target_user, updated_at = NOW()
    WHERE source = 'career_seed';

    GET DIAGNOSTICS moved = ROW_COUNT;

    -- Also move legacy MVP seed (learning/startup) off admin@personal-os.local if present
    UPDATE entities e
    SET user_id = target_user, updated_at = NOW()
    FROM users u
    WHERE e.user_id = u.id
      AND u.email = 'admin@personal-os.local'
      AND e.source IN ('udemy', 'aws', 'manual', 'fash', 'work', 'seed', 'research', 'inbox');

    UPDATE relationships r
    SET user_id = target_user
    WHERE r.user_id <> target_user
      AND (
          EXISTS (SELECT 1 FROM entities e WHERE e.id = r.source_entity_id AND (e.source = 'career_seed' OR e.user_id = target_user))
          OR EXISTS (SELECT 1 FROM entities e WHERE e.id = r.target_entity_id AND (e.source = 'career_seed' OR e.user_id = target_user))
      );

    UPDATE ai.embedding_jobs j
    SET user_id = target_user, status = 'pending', attempts = 0, last_error = ''
    WHERE j.source_table = 'entities'
      AND EXISTS (SELECT 1 FROM entities e WHERE e.id = j.entity_id AND e.user_id = target_user);

    UPDATE reminders rem
    SET user_id = target_user
    FROM entities e
    WHERE rem.entity_id = e.id AND e.user_id = target_user AND rem.user_id <> target_user;

    RAISE NOTICE 'Career owner: % (id=%). career_seed rows=%. Check: SELECT COUNT(*) FROM entities WHERE domain=''work'' AND user_id=''%'';', target_email, target_user, moved, target_user;
END $$;
