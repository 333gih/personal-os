-- Run career migrations 008 then 009 in order (psql meta-commands).
-- Usage from repo root:
--   psql "$DATABASE_URL" -f backend/migrations/010_work_career_all.sql
--
-- Or from backend/:
--   psql "$DATABASE_URL" -f migrations/010_work_career_all.sql

\echo '==> 008_work_career_data.sql'
\ir 008_work_career_data.sql
\echo '==> 009_work_design_cv.sql'
\ir 009_work_design_cv.sql
\echo '==> Career migrations complete'
