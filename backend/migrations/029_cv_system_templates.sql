-- Mark default CV templates as system-owned; runtime backfills empty blocks from work_cv_document.
-- psql $DATABASE_URL -f migrations/029_cv_system_templates.sql

UPDATE entities
SET metadata = metadata || jsonb_build_object('is_system', true)
WHERE type = 'work_cv_template'
  AND status = 'active'
  AND COALESCE(metadata->>'name', content) = 'Default (1-page)';
