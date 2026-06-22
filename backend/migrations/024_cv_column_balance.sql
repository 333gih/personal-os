-- CV v6.1: expand right-column content (ATS keywords) + balanced layout data
-- psql $DATABASE_URL -f migrations/024_cv_column_balance.sql

DO $$
DECLARE
    admin_id UUID;
    career_owner_email TEXT := 'mphuc8671@gmail.com';
BEGIN
    SELECT id INTO admin_id FROM users
    WHERE lower(trim(email)) = lower(trim(career_owner_email))
    LIMIT 1;

    IF admin_id IS NULL THEN
        RAISE NOTICE 'Career owner % not found — skip CV column balance update', career_owner_email;
        RETURN;
    END IF;

    UPDATE entities SET
        metadata = metadata || '{
        "years_experience": 3.5,
        "primary_stack": ["Java", "Spring Boot 3", "Next.js", "TypeScript", "AEM", "NestJS", "PostgreSQL"],
        "experience": [
            {
                "title": "Software Engineer",
                "company": "FPT Software",
                "period": "2025 — Now",
                "content": "Enterprise delivery for Japanese clients: Horserace betting platform system design, AEM + Spring Boot services.\nLayered BFF/API/batch architecture, performance optimization, CI/CD on GCP.\nRESTful APIs, GraphQL, Algolia search, Content Fragments, Spring Boot 3 migrations."
            },
            {
                "title": "Middle Developer cum Backend Lead",
                "company": "DHA Corporation + Tini Group (Techheart)",
                "period": "2024 — 2025",
                "content": "Led NestJS backends for Tini Coworking and Tini Trade — dual Admin/User APIs, MongoDB, Docker VPS.\nIntegrated IoT devices (smart locks, AC, cameras, printers, RFID parking).\nRabbitMQ async pipelines; mentored juniors; AI-assisted boilerplate and unit tests."
            },
            {
                "title": "Junior Backend Developer",
                "company": "Tech SaaS Cloud Innovations (Odisha, India)",
                "period": "2023 — 2024",
                "content": "Full-stack applications with backend–frontend integration on Node.js and Next.js.\nDeployed on Ubuntu/AWS; authored technical documentation for maintenance and onboarding."
            }
        ],
        "projects": [
            {
                "title": "Horserace — JP Horse-Racing Betting Platform",
                "company": "FPT Software",
                "period": "6/2026 — Present",
                "content": "Designed multi-tier architecture: Client → Next.js 15/React 19 → API Gateway → NLB → BFF → Domain API → PostgreSQL + Batch tier.\nAuthored front-end logical view: Atomic Design, Redux Toolkit, React Hook Form/Yup, Storybook, MSW, Vite/Jest.\nDefined Spring Boot 3.4 backend layers: BFF templates, REST API, Spring Batch Reader/Processor/Writer abstractions.\nStandardized cross-cutting modules: validation, exception handling, i18n, pagination, SpringDoc OpenAPI.\nCollaborated with Japanese stakeholders on system design documentation and release planning.\nTechnologies: Java, Spring Boot 3.4, Spring Batch, Spring Security, TypeScript, Next.js 15, PostgreSQL, Gradle."
            },
            {
                "title": "Destu Project (Chugai) — Software Engineer",
                "company": "FPT Software",
                "period": "3/2026 — Present",
                "content": "Built AEM Cloud components, templates, and servlets for enterprise pharmaceutical content.\nImplemented Author → +CAS content sync via REST API (JWT) and custom replication workflows.\nSupported AEM 6.5 to AEM Cloud migration with Probo; improved component reusability.\nTechnologies: AEM Cloud, Java, Sling, Workflows, PostgreSQL, MongoDB | Team: 50"
            },
            {
                "title": "Vietnam Airline Ticket Application — Software Engineer",
                "company": "FPT Software",
                "period": "9/2025 — 4/2026",
                "content": "Implemented Algolia global search on AEM publish workflow for Content Fragments and FAQ modules.\nDesigned reusable cross-team search indexing pattern for dynamic page components.\nIntegrated middleware for Amadeus/Gimasys and cloud edge services (WAF, load balancer).\nTechnologies: AEM, Algolia, Java, HTL | Team: 150"
            },
            {
                "title": "Canon Bundle Project (Nw3s) — Software Engineer",
                "company": "FPT Software",
                "period": "3/2025 — 10/2025",
                "content": "Migrated Spring Boot 2→3 and Java 7→11; Oracle→PostgreSQL for enterprise content pipeline.\nBuilt FTP/SFTP → XML → XSL → AEM Content Fragment workflow with custom process steps.\nIntegrated GraphQL + Elasticsearch for troubleshoot SEO; GCP Cloud Run scheduled jobs.\nAchieved 50%+ unit test coverage; Thymeleaf workflow portal for authors.\nTechnologies: Spring Boot 3, AEM, GCP, PostgreSQL, Elasticsearch | Team: 135"
            },
            {
                "title": "Tini Coworking — Space Management Platform",
                "company": "DHA Corporation + Tini Group (Techheart)",
                "period": "6/2024 — 3/2025",
                "content": "Architected dual NestJS backends (Admin/User) with Next.js web and mobile member app.\nBuilt IoT gateway unifying smart locks, AC, cameras, printers, and RFID parking APIs.\nImplemented NFT-based room listing (campus → block → floor → room) on blockchain marketplace.\nRabbitMQ workers for async device commands and booking notifications on Docker/Ubuntu VPS.\nTechnologies: NestJS, Next.js, MongoDB, RabbitMQ, Docker, IoT integrations"
            },
            {
                "title": "Tini Trade — Trading Platform",
                "company": "DHA Corporation + Tini Group (Techheart)",
                "period": "4/2024 — 5/2024",
                "content": "Developed dual NestJS backends with Next.js Admin/User frontends and trader mobile app.\nImplemented market listing, order management, and portfolio tracking APIs on MongoDB.\nRabbitMQ async pipeline for settlement, alerts, and webhook fan-out without blocking HTTP.\nTechnologies: NestJS, React, Next.js, MongoDB, RabbitMQ, Docker"
            },
            {
                "title": "Flow Diagram Builder — Full-stack SaaS Tool",
                "company": "Tech SaaS Cloud Innovations (Odisha, India)",
                "period": "2022 — 2023",
                "content": "Built drag-and-drop flow diagram editor (draw.io-style) with React Flow and Next.js canvas.\nNode.js REST API for diagram persistence; deployed on Ubuntu/AWS with stakeholder demos.\nTechnologies: Next.js, React Flow, Node.js, PostgreSQL"
            }
        ]
        }'::jsonb,
        updated_at = NOW()
    WHERE id = 'a000000a-0001-4001-8001-000000000001'::uuid AND user_id = admin_id;

    RAISE NOTICE 'CV column balance content updated for %', career_owner_email;
END $$;
