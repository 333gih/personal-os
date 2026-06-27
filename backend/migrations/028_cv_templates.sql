-- CV multi-template: migrate existing work_cv_document into work_cv_template
-- psql $DATABASE_URL -f migrations/028_cv_templates.sql

DO $$
DECLARE
    rec RECORD;
    meta JSONB;
BEGIN
    FOR rec IN
        SELECT id, user_id, title, content, metadata, updated_at
        FROM entities
        WHERE type = 'work_cv_document' AND status = 'active'
    LOOP
        IF EXISTS (
            SELECT 1 FROM entities t
            WHERE t.user_id = rec.user_id AND t.type = 'work_cv_template' AND t.status = 'active'
        ) THEN
            CONTINUE;
        END IF;

        meta := COALESCE(rec.metadata, '{}'::jsonb) || jsonb_build_object(
            'layout_id', 'two_column_one_page_v5',
            'is_default', true,
            'name', 'Default (1-page)',
            'constraints', jsonb_build_object('max_pages', 1, 'max_experience', 4, 'max_projects', 8),
            'blocks', '[]'::jsonb
        );

        INSERT INTO entities (user_id, type, title, content, tags, source, metadata, domain, status)
        VALUES (
            rec.user_id,
            'work_cv_template',
            'CV Template — Default (1-page)',
            'Default (1-page)',
            '["cv","template"]'::jsonb,
            'cv_system',
            meta,
            'work',
            'active'
        );
    END LOOP;
END $$;
