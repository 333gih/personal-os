-- Professional CV profile + rename system templates (no "Default" / "AI Recommended" labels).
-- psql $DATABASE_URL -f migrations/031_cv_profile_and_template_names.sql

DO $$
DECLARE
    admin_id UUID;
    career_owner_email TEXT := 'mphuc8671@gmail.com';
BEGIN
    SELECT id INTO admin_id FROM users
    WHERE lower(trim(email)) = lower(trim(career_owner_email))
    LIMIT 1;

    IF admin_id IS NULL THEN
        RAISE NOTICE 'Career owner % not found — skip CV profile update', career_owner_email;
        RETURN;
    END IF;

    UPDATE entities SET
        title = 'CV — Nguyen Khoa Minh Phuc — Software Engineer',
        content = 'Software Engineer with a backend focus on Java, Spring Boot, and enterprise system design — BFF/API/batch tiers, AEM-Java integration, PostgreSQL, and Japanese client delivery. Strong in REST API design, batch processing, performance tuning, and CI/CD. Comfortable collaborating on TypeScript/React front-ends; primary strength is backend delivery.',
        metadata = metadata || '{
        "headline": "Nguyen Khoa Minh Phuc — Software Engineer",
        "summary": "Software Engineer with a backend focus on Java, Spring Boot, and enterprise system design — BFF/API/batch tiers, AEM-Java integration, PostgreSQL, and Japanese client delivery. Strong in REST API design, batch processing, performance tuning, and CI/CD. Comfortable collaborating on TypeScript/React front-ends; primary strength is backend delivery.",
        "contact": {
            "email": "mphuc8671@gmail.com",
            "phone": "+84 972 495 038",
            "location": "Ho Chi Minh City, Vietnam",
            "linkedin": "https://www.linkedin.com/in/minh-phuc-774110229/",
            "github": "https://github.com/phuckhoa33"
        }
        }'::jsonb,
        updated_at = NOW()
    WHERE user_id = admin_id AND type = 'work_cv_document' AND status = 'active';

    UPDATE entities SET
        title = 'CV Template — Professional CV (1 page)',
        content = 'Professional CV (1 page)',
        metadata = metadata
            || jsonb_build_object('name', 'Professional CV (1 page)', 'is_system', true, 'blocks', '[]'::jsonb),
        updated_at = NOW()
    WHERE user_id = admin_id
      AND type = 'work_cv_template'
      AND status = 'active'
      AND COALESCE(metadata->>'name', content) IN ('Default (1-page)', 'Professional CV (1 page)');

    UPDATE entities SET
        title = 'CV Template — Stack-optimized CV',
        content = 'Stack-optimized CV',
        metadata = metadata
            || jsonb_build_object('name', 'Stack-optimized CV', 'is_system', true, 'blocks', '[]'::jsonb),
        updated_at = NOW()
    WHERE user_id = admin_id
      AND type = 'work_cv_template'
      AND status = 'active'
      AND COALESCE(metadata->>'name', content) IN ('AI Recommended', 'Stack-optimized CV');

    RAISE NOTICE 'CV profile + template names updated for %', career_owner_email;
END $$;
