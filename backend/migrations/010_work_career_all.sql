-- Career data bootstrap for mphuc8671@gmail.com
--
-- BEFORE RUNNING (required):
--   1. Log in to Personal OS web or iOS as mphuc8671@gmail.com (Fash Auth).
--      This creates your user row with the correct JWT user id.
--   2. Then run this file from backend/:
--        psql "$DATABASE_URL" -f migrations/010_work_career_all.sql
--
-- Verify:
--   SELECT email, id FROM users WHERE email ILIKE 'mphuc8671@gmail%';
--   SELECT COUNT(*) FROM entities e JOIN users u ON u.id=e.user_id
--     WHERE u.email ILIKE 'mphuc8671@gmail%' AND e.domain='work';

\echo '==> 012_career_owner_functions.sql'
\ir 012_career_owner_functions.sql
\echo '==> 008_work_career_data.sql'
\ir 008_work_career_data.sql
\echo '==> 009_work_design_cv.sql'
\ir 009_work_design_cv.sql
\echo '==> 011_work_career_assign_user.sql'
\ir 011_work_career_assign_user.sql
\echo '==> Career migrations complete for mphuc8671@gmail.com'
