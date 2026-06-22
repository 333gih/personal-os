-- CV: expand right column (experience + projects) to balance page with left column
-- psql $DATABASE_URL -f migrations/025_cv_right_column_expanded.sql

DO $$
DECLARE
    admin_id UUID;
    career_owner_email TEXT := 'mphuc8671@gmail.com';
BEGIN
    SELECT id INTO admin_id FROM users
    WHERE lower(trim(email)) = lower(trim(career_owner_email))
    LIMIT 1;

    IF admin_id IS NULL THEN
        RAISE NOTICE 'Career owner % not found — skip CV right column expand', career_owner_email;
        RETURN;
    END IF;

    UPDATE entities SET
        metadata = metadata || '{
        "experience": [
            {
                "title": "Software Engineer",
                "company": "FPT Software",
                "period": "2025 — Now",
                "content": "Enterprise delivery for Japanese clients: Horserace betting platform system design, AEM + Spring Boot services.\nLayered BFF/API/batch architecture, performance optimization, CI/CD on GCP.\nRESTful APIs, GraphQL, Algolia search, Content Fragments, and Spring Boot 3 migrations."
            },
            {
                "title": "Middle Developer cum Backend Lead",
                "company": "DHA Corporation + Tini Group (Techheart)",
                "period": "2024 — 2025",
                "content": "Led NestJS backends for Tini Coworking and Tini Trade — dual Admin/User APIs, MongoDB, Docker VPS.\nIntegrated IoT devices (smart locks, AC, cameras, printers, RFID parking).\nRabbitMQ async pipelines; mentored juniors; AI tools for boilerplate and unit tests."
            },
            {
                "title": "Junior Backend Developer",
                "company": "Tech SaaS Cloud Innovations (Odisha, India)",
                "period": "2023 — 2024",
                "content": "Developed full-stack applications with seamless backend–frontend integration on Node.js and Next.js.\nCollaborated with stakeholders to translate business needs into technical solutions.\nDeployed and optimized applications on Ubuntu/AWS; authored technical documentation."
            }
        ],
        "projects": [
            {
                "title": "Horserace — JP Horse-Racing Betting Platform",
                "company": "FPT Software",
                "period": "6/2026 — Present",
                "content": "System design: Client → Frontend (Next.js 15/React 19) → API Gateway → NLB → BFF → Domain API → PostgreSQL + Batch tier.\nFront-end logical view: Atomic Design, Redux Toolkit, React Hook Form/Yup, Storybook, MSW, Vite/Jest.\nBack-end layers: Spring Boot 3.4 BFF request/response templates, REST API, Spring Batch Reader/Processor/Writer.\nCross-cutting: validation, exception handling, i18n, pagination, SpringDoc OpenAPI for Japanese enterprise release.\nCollaborated with client architects on application architecture overview and batch settlement workflows.\nTech: Java, Spring Boot 3.4, Spring Batch, Spring Security, TypeScript, Next.js 15, PostgreSQL, Gradle"
            },
            {
                "title": "Destu Project (Chugai) — Software Engineer",
                "company": "FPT Software",
                "period": "3/2026 — Present",
                "content": "Developed AEM Cloud components, templates, and servlets for enterprise pharmaceutical content.\nImplemented Author → +CAS content sync via REST API (JWT) and custom replication workflows.\nSupported AEM 6.5 to AEM Cloud migration with Probo; improved component reusability.\nCollaborated with Japanese client stakeholders on legacy workflow improvements.\nTech: AEM Cloud, Java, Sling, Workflows, PostgreSQL, MongoDB | Team: 50"
            },
            {
                "title": "Vietnam Airline Ticket Application — Software Engineer",
                "company": "FPT Software",
                "period": "9/2025 — 4/2026",
                "content": "Developed search features using Algolia Search on AEM publish workflow.\nDesigned AEM components, templates, and servlets for global search functionality.\nAggregated Content Fragment + FAQ + dynamic page data from cross-team components.\nIntegrated middleware for Amadeus/Gimasys and cloud edge services (WAF, load balancer).\nTech: AEM, Algolia, Java, HTL | Team: 150"
            },
            {
                "title": "Canon Bundle Project (Nw3s) — Software Engineer",
                "company": "FPT Software",
                "period": "3/2025 — 10/2025",
                "content": "Migrated Spring Boot 2→3 and Java 7→11; Oracle→PostgreSQL for enterprise content pipeline.\nBuilt FTP/SFTP → XML → XSL → AEM Content Fragment workflow with custom process steps.\nIntegrated GraphQL + Elasticsearch for troubleshoot SEO; GCP Cloud Run scheduled jobs.\nDeveloped Thymeleaf workflow portal; achieved 50%+ unit test coverage.\nTech: Spring Boot 3, AEM, GCP Cloud Run, PostgreSQL, Elasticsearch | Team: 135"
            },
            {
                "title": "Tini Coworking — Space Management Platform",
                "company": "DHA Corporation + Tini Group (Techheart)",
                "period": "6/2024 — 3/2025",
                "content": "Dual NestJS backends (Admin/User), Next.js web, mobile app, MongoDB on Docker VPS.\nIoT gateway: smart locks, AC, cameras, printers, RFID parking (monthly/casual).\nNFT room listing (campus → block → floor → room) on blockchain marketplace.\nRabbitMQ async workers for device commands, booking notifications, and paper orders.\nBackend lead: CI/CD on Ubuntu VPS, API design, mentoring junior developers.\nTech: NestJS, Next.js, MongoDB, RabbitMQ, Docker, IoT integrations"
            },
            {
                "title": "Tini Trade — Trading Platform",
                "company": "DHA Corporation + Tini Group (Techheart)",
                "period": "4/2024 — 5/2024",
                "content": "Dual NestJS backends with Next.js Admin/User frontends and trader mobile app.\nMarket listing, order management, portfolio tracking APIs on MongoDB.\nRabbitMQ async pipeline for settlement, alerts, and webhook fan-out.\nDocker deployment on Ubuntu VPS; collaborated with web and mobile teams.\nTech: NestJS, React, Next.js, MongoDB, RabbitMQ, Docker"
            },
            {
                "title": "Flow Diagram Builder — Full-stack SaaS Tool",
                "company": "Tech SaaS Cloud Innovations (Odisha, India)",
                "period": "2022 — 2023",
                "content": "Built drag-and-drop flow diagram editor (draw.io-style) with React Flow and Next.js.\nNode.js REST API for diagram persistence and collaboration features.\nDeployed on Ubuntu/AWS; authored technical documentation for maintenance.\nTech: Next.js, React Flow, Node.js, PostgreSQL"
            }
        ]
        }'::jsonb,
        updated_at = NOW()
    WHERE id = 'a000000a-0001-4001-8001-000000000001'::uuid AND user_id = admin_id;

    RAISE NOTICE 'CV right column expanded for %', career_owner_email;
END $$;
