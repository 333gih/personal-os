-- CV: refocus left column on Java/Spring Boot backend; keep right column from 025
-- psql $DATABASE_URL -f migrations/026_cv_left_java_backend.sql

DO $$
DECLARE
    admin_id UUID;
    career_owner_email TEXT := 'mphuc8671@gmail.com';
BEGIN
    SELECT id INTO admin_id FROM users
    WHERE lower(trim(email)) = lower(trim(career_owner_email))
    LIMIT 1;

    IF admin_id IS NULL THEN
        RAISE NOTICE 'Career owner % not found — skip CV left column Java backend', career_owner_email;
        RETURN;
    END IF;

    UPDATE entities SET
        content = 'Backend Software Engineer focused on Java, Spring Boot, and enterprise system design (BFF, REST API, Spring Batch, AEM). Primary backend delivery with front-end capability when needed.',
        metadata = metadata || '{
        "headline": "Nguyen Khoa Minh Phuc — Backend Software Engineer",
        "summary": "Backend Software Engineer specializing in Java and Spring Boot (Spring Batch, Spring Security, Spring Data) for enterprise systems. Core expertise in layered architecture — BFF/API/batch tiers, AEM-Java integration, PostgreSQL, and Japanese client delivery (Horserace betting platform). Strong in REST API design, batch processing, performance tuning, CI/CD, and SOLID principles. Can contribute to TypeScript/React front-ends when needed; primary focus and strength is backend system development.",
        "primary_stack": ["Java", "Spring Boot", "Spring Batch", "AEM", "PostgreSQL"],
        "skill_groups": [
            {"category": "Java & Spring Boot", "items": ["Java 17", "Spring Boot 3.4", "Spring Batch", "Spring Security", "Spring Data JPA", "SpringDoc OpenAPI", "Gradle/Maven", "SOLID & design patterns"]},
            {"category": "Enterprise Systems", "items": ["REST/BFF layering", "API Gateway topology", "microservices patterns", "gRPC", "distributed batch jobs", "RabbitMQ/Kafka async pipelines"]},
            {"category": "AEM & Java Integration", "items": ["AEM Cloud / 6.5", "Java Sling/OSGi servlets", "workflows & replication", "Content Fragments", "HTL components", "Author→Publish REST sync"]},
            {"category": "Data & Infrastructure", "items": ["PostgreSQL", "MySQL", "Oracle", "MongoDB", "Redis", "Elasticsearch/Algolia", "Docker", "CI/CD", "GCP"]},
            {"category": "Frontend (supporting)", "items": ["TypeScript", "React", "Next.js — integration & UI collaboration; backend is primary strength"]}
        ],
        "achievements": [
            {"content": "Authored layered Horserace system design (JP betting): Screen API BFF, Domain REST API, and Spring Batch settlement/report modules."},
            {"content": "Built and optimized Java/Spring Boot services for high-volume enterprise workloads with PostgreSQL, Redis caching, and CI/CD on GCP."},
            {"content": "Led Spring Boot 2→3 and Java 7→11 migrations; FTP/XML→AEM Content Fragment pipelines with GraphQL and Elasticsearch (Canon Bundle)."},
            {"content": "Delivered AEM Cloud Java components, servlets, and REST sync workflows for pharmaceutical (Chugai) and airline enterprise clients."},
            {"content": "Standardized REST contracts, validation, exception handling, and OpenAPI documentation across BFF and domain API layers."},
            {"content": "Designed scalable backend APIs and async processing for multi-tenant platforms; comfortable pairing with Next.js/React teams when needed."}
        ]
        }'::jsonb,
        updated_at = NOW()
    WHERE id = 'a000000a-0001-4001-8001-000000000001'::uuid AND user_id = admin_id;

    RAISE NOTICE 'CV left column refocused on Java/Spring Boot backend for %', career_owner_email;
END $$;
