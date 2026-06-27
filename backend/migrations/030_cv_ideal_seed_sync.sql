-- Reseed ideal CV document + clear empty system template blocks (runtime repopulates from Go seed).
-- psql $DATABASE_URL -f migrations/030_cv_ideal_seed_sync.sql

DO $$
DECLARE
    admin_id UUID;
    career_owner_email TEXT := 'mphuc8671@gmail.com';
BEGIN
    SELECT id INTO admin_id FROM users
    WHERE lower(trim(email)) = lower(trim(career_owner_email))
    LIMIT 1;

    IF admin_id IS NULL THEN
        RAISE NOTICE 'Career owner % not found — skip CV ideal seed sync', career_owner_email;
        RETURN;
    END IF;

    UPDATE entities SET
        title = 'CV — Nguyen Khoa Minh Phuc — Backend Software Engineer',
        content = 'Backend Software Engineer specializing in Java and Spring Boot for enterprise systems — BFF/API/batch tiers, AEM-Java integration, PostgreSQL, and Japanese client delivery. Strong in REST API design, batch processing, performance tuning, and CI/CD. Comfortable with TypeScript/React front-ends for integration; primary strength is backend system development.',
        metadata = metadata || '{
        "headline": "Nguyen Khoa Minh Phuc — Backend Software Engineer",
        "summary": "Backend Software Engineer specializing in Java and Spring Boot for enterprise systems — BFF/API/batch tiers, AEM-Java integration, PostgreSQL, and Japanese client delivery. Strong in REST API design, batch processing, performance tuning, and CI/CD. Comfortable with TypeScript/React front-ends for integration; primary strength is backend system development.",
        "contact": {
            "email": "phuckhoa81@gmail.com",
            "phone": "+(84) 972495038",
            "location": "Ho Chi Minh City, Vietnam",
            "linkedin": "linkedin.com/in/nguyen-khoa-minh-phuc",
            "github": "github.com/mphuc8671"
        },
        "primary_stack": ["Java", "Spring Boot", "Spring Batch", "AEM", "PostgreSQL"],
        "education": [
            {"school": "Ho Chi Minh Open University (OU)", "period": "Present", "content": "Pursuing a Bachelor''s degree in Information Technology."},
            {"school": "FPT Polytechnic College", "period": "Graduated", "content": "Graduated with a strong foundation in software development and engineering principles."}
        ],
        "achievements": [
            {"content": "Authored Horserace layered system design: BFF, Domain REST API, Spring Batch settlement/report modules for JP betting platform."},
            {"content": "Built Java/Spring Boot services for high-volume workloads — PostgreSQL, Redis caching, CI/CD on GCP."},
            {"content": "Led Spring Boot 2→3 and Java 7→11 migrations; FTP/XML→AEM Content Fragment pipelines (Canon Bundle)."},
            {"content": "Delivered AEM Cloud Java components and REST sync workflows for pharmaceutical and airline enterprise clients."},
            {"content": "Designed scalable APIs and async processing for multi-tenant platforms; mentors junior backend developers."},
            {"content": "Integrated IoT device APIs and RabbitMQ async pipelines for Tini Coworking — dual Spring Boot Admin/User backends."}
        ],
        "certificates": [
            {"title": "CodeGym Certification", "issuer": "Technical certification in software development."},
            {"title": "Coursera Certifications", "issuer": "Software development and database management courses."},
            {"title": "Google Certifications", "issuer": "Modern cloud technologies and best practices."}
        ],
        "skill_groups": [
            {"category": "Java & Spring Boot", "items": ["Java 17", "Spring Boot 3.4", "Spring Batch", "Spring Security", "Spring Data JPA", "OpenAPI", "Gradle/Maven"]},
            {"category": "Enterprise Systems", "items": ["REST/BFF layering", "API Gateway", "microservices", "gRPC", "batch jobs", "RabbitMQ/Kafka"]},
            {"category": "AEM & Java", "items": ["AEM Cloud / 6.5", "Sling/OSGi servlets", "workflows", "Content Fragments", "Author→Publish REST sync"]},
            {"category": "Data & DevOps", "items": ["PostgreSQL", "MySQL", "MongoDB", "Redis", "Elasticsearch", "Docker", "CI/CD", "GCP"]},
            {"category": "Frontend (supporting)", "items": ["TypeScript", "React", "Next.js — UI integration when needed"]}
        ],
        "experience": [
            {"title": "Software Engineer", "company": "FPT Software", "period": "2025 — Now", "content": "Backend-focused delivery for Japanese clients: Horserace betting platform system design, AEM + Spring Boot services.\nLayered BFF/API/batch architecture, REST/GraphQL APIs, performance optimization, CI/CD on GCP."},
            {"title": "Middle Developer cum Backend Lead", "company": "DHA Corporation + Tini Group (Techheart)", "period": "2024 — 2025", "content": "Led Java Spring Boot backends for Tini Coworking and Tini Trade — dual Admin/User APIs, MongoDB, Docker VPS.\nIntegrated IoT devices (smart locks, AC, cameras, RFID parking); RabbitMQ async pipelines.\nBackend lead: API design, CI/CD, mentoring juniors."},
            {"title": "Junior Backend Developer", "company": "Tech SaaS Cloud Innovations (Odisha, India)", "period": "2023 — 2024", "content": "Built full-stack features with Node.js and Next.js — backend–frontend integration, stakeholder collaboration.\nDeployed and optimized on Ubuntu/AWS; authored technical documentation."}
        ],
        "projects": [
            {"title": "Horserace — JP Horse-Racing Betting Platform", "company": "FPT Software", "period": "6/2026 — Present", "content": "System design: API Gateway → BFF → Domain REST API → PostgreSQL + Spring Batch tier.\nSpring Boot 3.4 BFF/REST/Batch modules — validation, i18n, pagination, SpringDoc OpenAPI.\nTech: Java, Spring Boot 3.4, Spring Batch, PostgreSQL, Gradle"},
            {"title": "Destu Project (Chugai) — Software Engineer", "company": "FPT Software", "period": "3/2026 — Present", "content": "AEM Cloud components, servlets, Author→Publish REST sync (JWT) for pharmaceutical content.\nTech: AEM Cloud, Java, Sling, Workflows | Team: 50"},
            {"title": "Vietnam Airline Ticket Application — Software Engineer", "company": "FPT Software", "period": "9/2025 — 4/2026", "content": "Algolia search on AEM publish; components, templates, servlets for global search.\nTech: AEM, Algolia, Java, HTL | Team: 150"},
            {"title": "Canon Bundle Project (Nw3s) — Software Engineer", "company": "FPT Software", "period": "3/2025 — 10/2025", "content": "Spring Boot 2→3, Java 7→11; FTP/SFTP→XML→AEM Content Fragment pipeline; GraphQL + Elasticsearch.\nTech: Spring Boot 3, AEM, GCP Cloud Run, PostgreSQL | Team: 135"},
            {"title": "Tini Coworking — Space Management Platform", "company": "DHA Corporation + Tini Group (Techheart)", "period": "6/2024 — 3/2025", "content": "Dual Java Spring Boot backends (Admin/User), MongoDB, Docker VPS; IoT gateway for locks, AC, cameras, RFID parking.\nRabbitMQ async workers for bookings and device commands; backend lead for API design and CI/CD.\nTech: Java, Spring Boot, MongoDB, RabbitMQ, Docker"},
            {"title": "Tini Trade — Trading Platform", "company": "DHA Corporation + Tini Group (Techheart)", "period": "4/2024 — 5/2024", "content": "Dual Java Spring Boot APIs — market listing, orders, portfolio on MongoDB; RabbitMQ settlement pipeline.\nTech: Java, Spring Boot, MongoDB, RabbitMQ, Docker"},
            {"title": "Flow Diagram Builder — Full-stack SaaS Tool", "company": "Tech SaaS Cloud Innovations (Odisha, India)", "period": "2022 — 2023", "content": "Drag-and-drop flow editor (React Flow) with Node.js REST API for diagram persistence.\nTech: Next.js, React Flow, Node.js, PostgreSQL"}
        ]
        }'::jsonb,
        updated_at = NOW()
    WHERE user_id = admin_id AND type = 'work_cv_document' AND status = 'active';

    UPDATE entities
    SET metadata = metadata || jsonb_build_object('blocks', '[]'::jsonb, 'is_system', true)
    WHERE user_id = admin_id
      AND type = 'work_cv_template'
      AND status = 'active'
      AND COALESCE(metadata->>'name', content) IN ('Default (1-page)', 'AI Recommended');

    RAISE NOTICE 'CV ideal seed sync applied for %', career_owner_email;
END $$;
