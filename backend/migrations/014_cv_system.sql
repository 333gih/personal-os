-- Ideal CV document seed for career owner
-- psql $DATABASE_URL -f migrations/014_cv_system.sql

DO $$
DECLARE
    admin_id UUID;
    career_owner_email TEXT := 'mphuc8671@gmail.com';
BEGIN
    SELECT id INTO admin_id FROM users
    WHERE lower(trim(email)) = lower(trim(career_owner_email))
    LIMIT 1;

    IF admin_id IS NULL THEN
        RAISE NOTICE 'Career owner % not found — skip CV seed until first login', career_owner_email;
        RETURN;
    END IF;

    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status) VALUES
    ('a000000a-0001-4001-8001-000000000001'::uuid, admin_id, 'work_cv_document', 'CV — Software Engineer (Ideal)',
     'Enterprise AEM/Spring Boot engineer with NestJS backend lead experience. Strong in migration pipelines, global search (Algolia), and IoT platforms.',
     '["cv","ideal","transfer"]'::jsonb, 'cv_system',
     '{
        "variant": "ideal",
        "headline": "Nguyen Khoa Minh Phuc — Software Engineer",
        "summary": "Software Engineer specializing in Java, AEM, and Spring Boot with scalable backend systems, API integrations, and performance optimization. Background in NestJS/Node.js (TINI Group), transitioned to enterprise AEM + Spring Boot at FPT Software.",
        "contact": {
            "email": "mphuc8671@gmail.com",
            "location": "Ho Chi Minh City, Vietnam"
        },
        "skills": ["Adobe Experience Manager", "Spring Boot", "Java", "NestJS", "Algolia", "GCP Cloud Run", "PostgreSQL", "MongoDB", "Elasticsearch", "GraphQL"],
        "experience": [
            {"title": "Software Engineer", "company": "FPT Software", "period": "2025 — Present", "content": "AEM components, Spring Boot 3 migration, enterprise delivery for Canon NW3S, Vietnam Airlines, Destu/Chugai."},
            {"title": "Backend Lead", "company": "TINI GROUP", "period": "2024 — 2025", "content": "Led NestJS APIs, Docker VPS, IoT integrations (doors, AC, printers), mentored juniors."},
            {"title": "Full-stack Developer", "company": "Tech Saas Cloud Innovations", "period": "2022 — 2023", "content": "Full-stack apps, Ubuntu/AWS deploy, technical documentation."}
        ],
        "projects": [
            {"title": "Canon NW3S — Documentum to AEM Migration", "company": "FPT Software", "period": "2025", "content": "FTP→XML→XSL→AEM workflow, Content Fragments, Spring Boot 3, GCP Cloud Run, Elasticsearch SEO."},
            {"title": "Vietnam Airlines — Algolia Global Search", "company": "FPT Software", "period": "2025 — 2026", "content": "Publish workflow indexes CF + FAQ + components to Algolia; reusable cross-team search pattern."},
            {"title": "Destu (Chugai) — AEM Cloud Migration", "company": "FPT Software", "period": "2026 — Present", "content": "AEM 6.5 → Cloud, content sync Author → +CAS via REST API."},
            {"title": "Tini Coworking — Space Management Platform", "company": "TINI GROUP", "period": "2024 — 2025", "content": "Dual NestJS backends, IoT gateway, MongoDB, NFT room listing, RabbitMQ async."}
        ]
     }'::jsonb,
     'work', 'active')
    ON CONFLICT (id) DO UPDATE SET
        title = EXCLUDED.title,
        content = EXCLUDED.content,
        metadata = EXCLUDED.metadata,
        updated_at = NOW();

    RAISE NOTICE 'Ideal CV document seeded for %', career_owner_email;
END $$;
