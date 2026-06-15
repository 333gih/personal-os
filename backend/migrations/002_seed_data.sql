-- Seed data for Personal OS MVP
-- Run after migrations: psql $DATABASE_URL -f migrations/002_seed_data.sql

DO $$
DECLARE
    admin_id UUID;
    redis_id UUID;
    kafka_id UUID;
    catalog_id UUID;
    aws_cert_id UUID;
    aws_skill_id UUID;
    go_course_id UUID;
    startup_id UUID;
BEGIN
    SELECT id INTO admin_id FROM users WHERE email = 'admin@personal-os.local' LIMIT 1;
    IF admin_id IS NULL THEN
        RAISE NOTICE 'No admin user found. Start the API first to create default user.';
        RETURN;
    END IF;

    -- Learning domain
    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status)
    VALUES (gen_random_uuid(), admin_id, 'learning_course', 'Go Advanced Patterns',
        'Deep dive into interfaces, concurrency patterns, and clean architecture in Go.',
        '["golang", "backend", "architecture"]', 'udemy',
        '{"progress": 65, "provider": "Udemy", "url": "https://example.com/go-patterns"}',
        'learning', 'active')
    RETURNING id INTO go_course_id;

    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status)
    VALUES (gen_random_uuid(), admin_id, 'learning_certificate', 'AWS Solutions Architect Associate',
        'Certified AWS Solutions Architect - Associate level.',
        '["aws", "cloud", "certification"]', 'aws',
        '{"issued_at": "2025-03-15", "expires_at": "2028-03-15", "credential_id": "AWS-SAA-12345"}',
        'learning', 'active')
    RETURNING id INTO aws_cert_id;

    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status)
    VALUES (gen_random_uuid(), admin_id, 'learning_skill', 'AWS Cloud Architecture',
        'Designing scalable, fault-tolerant systems on AWS.',
        '["aws", "cloud", "architecture"]', 'manual',
        '{"level": "advanced", "years": 3}', 'learning', 'active')
    RETURNING id INTO aws_skill_id;

    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status)
    VALUES (gen_random_uuid(), admin_id, 'learning_topic', 'Distributed Systems',
        'Consensus, CAP theorem, event sourcing, CQRS.',
        '["distributed-systems", "architecture"]', 'manual',
        '{"priority": "high"}', 'learning', 'active');

    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status)
    VALUES (gen_random_uuid(), admin_id, 'learning_note', 'Interview: System Design Basics',
        'Start with requirements, estimate scale, draw components, discuss bottlenecks.',
        '["interview", "system-design"]', 'manual',
        '{"review_date": "2026-06-20"}', 'learning', 'active');

    -- Work domain
    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status)
    VALUES (gen_random_uuid(), admin_id, 'work_project', 'Marketplace Platform',
        'Multi-service marketplace with Traefik, Kong, Go microservices.',
        '["marketplace", "go", "docker"]', 'fash',
        '{"role": "Staff Engineer", "status": "active"}', 'work', 'active');

    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status)
    VALUES (gen_random_uuid(), admin_id, 'work_technology', 'Redis',
        'In-memory data store used for caching and session management.',
        '["redis", "cache", "performance"]', 'work',
        '{"category": "database"}', 'work', 'active')
    RETURNING id INTO redis_id;

    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status)
    VALUES (gen_random_uuid(), admin_id, 'work_technology', 'Kafka',
        'Event streaming platform for async communication between services.',
        '["kafka", "events", "messaging"]', 'work',
        '{"category": "messaging"}', 'work', 'active')
    RETURNING id INTO kafka_id;

    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status)
    VALUES (gen_random_uuid(), admin_id, 'work_problem', 'Catalog Performance Issue',
        'Product catalog API p99 latency spiked to 2s under load. Root cause: N+1 queries.',
        '["performance", "catalog", "database"]', 'work',
        '{"severity": "high", "resolved": true}', 'work', 'active')
    RETURNING id INTO catalog_id;

    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status)
    VALUES (gen_random_uuid(), admin_id, 'work_decision', 'Use Redis for Catalog Cache',
        'Decision to add Redis caching layer with 5-minute TTL for catalog listings.',
        '["redis", "cache", "decision"]', 'work',
        '{"date": "2025-11-01", "status": "implemented"}', 'work', 'active');

    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status)
    VALUES (gen_random_uuid(), admin_id, 'work_lesson', 'Always Load Test Before Launch',
        'Performance issues found in staging load tests prevented production outage.',
        '["performance", "testing", "lesson"]', 'work',
        '{}', 'work', 'active');

    -- Startup domain
    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status)
    VALUES (gen_random_uuid(), admin_id, 'startup_idea', 'Personal Knowledge OS',
        'A self-hosted platform to manage learning, work experience, and startup ideas with AI assistance.',
        '["saas", "knowledge", "ai"]', 'inbox',
        '{"stage": "mvp", "priority": "high"}', 'startup', 'active')
    RETURNING id INTO startup_id;

    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status)
    VALUES (gen_random_uuid(), admin_id, 'startup_pain_point', 'Scattered Knowledge',
        'Developers lose track of lessons learned, certifications, and project decisions across tools.',
        '["productivity", "knowledge-management"]', 'research',
        '{"severity": "high"}', 'startup', 'active');

    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status)
    VALUES (gen_random_uuid(), admin_id, 'startup_competitor', 'Notion',
        'General-purpose workspace. Weak on structured relationships and AI-native knowledge graphs.',
        '["competitor", "notion"]', 'research',
        '{"url": "https://notion.so"}', 'startup', 'active');

    -- Inbox items
    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status)
    VALUES
        (gen_random_uuid(), admin_id, 'inbox_url', 'Pgvector Documentation',
         'https://github.com/pgvector/pgvector - vector similarity search for PostgreSQL',
         '["postgres", "vector", "search"]', 'url',
         '{"input_type": "url"}', 'inbox', 'active'),
        (gen_random_uuid(), admin_id, 'inbox_note', 'Quick idea: plugin marketplace',
         'Allow third-party plugins for domain-specific workflows (fitness tracking, finance, etc.)',
         '["plugin", "idea"]', 'manual',
         '{"input_type": "note"}', 'inbox', 'active');

    -- Relationships
    INSERT INTO relationships (user_id, source_entity_id, target_entity_id, relation_type)
    VALUES
        (admin_id, redis_id, catalog_id, 'solved'),
        (admin_id, kafka_id, catalog_id, 'used_in'),
        (admin_id, aws_cert_id, aws_skill_id, 'proves');

    -- Reminders
    INSERT INTO reminders (user_id, entity_id, title, due_at, status)
    VALUES
        (admin_id, go_course_id, 'Continue Go Advanced Patterns course', NOW() + INTERVAL '3 days', 'pending'),
        (admin_id, aws_skill_id, 'Review AWS architecture patterns', NOW() + INTERVAL '7 days', 'pending');

    RAISE NOTICE 'Seed data inserted successfully for user %', admin_id;
END $$;
