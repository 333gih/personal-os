-- Assign career_seed entities to the primary login user (fixes Work tab showing 0 items).
-- Run after 010_work_career_all.sql if Work is empty while logged in.
-- psql $DATABASE_URL -f migrations/011_work_career_assign_user.sql

DO $$
DECLARE
    target_user UUID;
    target_email TEXT;
    career_count INT;
BEGIN
    SELECT u.id, u.email INTO target_user, target_email
    FROM users u
    WHERE u.email NOT LIKE '%@personal-os.local%'
    ORDER BY u.created_at ASC
    LIMIT 1;

    IF target_user IS NULL THEN
        SELECT u.id, u.email INTO target_user, target_email
        FROM users u
        ORDER BY u.created_at ASC
        LIMIT 1;
    END IF;

    IF target_user IS NULL THEN
        RAISE EXCEPTION 'No users in database. Log in once via the app first.';
    END IF;

    SELECT COUNT(*) INTO career_count FROM entities WHERE source = 'career_seed';

    IF career_count = 0 THEN
        RAISE EXCEPTION 'No career data found. Run: psql $DATABASE_URL -f migrations/010_work_career_all.sql';
    END IF;

    UPDATE entities
    SET user_id = target_user, updated_at = NOW()
    WHERE source = 'career_seed';

    UPDATE relationships r
    SET user_id = target_user
    WHERE EXISTS (
        SELECT 1 FROM entities e
        WHERE e.source = 'career_seed'
          AND (e.id = r.source_entity_id OR e.id = r.target_entity_id)
    );

    UPDATE ai.embedding_jobs j
    SET user_id = target_user, status = 'pending', attempts = 0, last_error = ''
    WHERE j.source_table = 'entities'
      AND EXISTS (
          SELECT 1 FROM entities e
          WHERE e.id = j.entity_id AND e.source = 'career_seed'
      );

    RAISE NOTICE 'Assigned % career entities to user % (%)', career_count, target_user, target_email;
END $$;
