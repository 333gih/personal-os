-- Refresh project bullet content + contact link labels (server reseed also applies via ideal_seed.go).
-- psql $DATABASE_URL -f migrations/032_cv_project_descriptions.sql

DO $$
DECLARE
    admin_id UUID;
    career_owner_email TEXT := 'mphuc8671@gmail.com';
BEGIN
    SELECT id INTO admin_id FROM users
    WHERE lower(trim(email)) = lower(trim(career_owner_email))
    LIMIT 1;

    IF admin_id IS NULL THEN
        RAISE NOTICE 'Career owner % not found — skip CV project refresh', career_owner_email;
        RETURN;
    END IF;

    UPDATE entities SET
        metadata = metadata || '{
        "contact": {
            "email": "mphuc8671@gmail.com",
            "phone": "+84 972 495 038",
            "location": "Ho Chi Minh City, Vietnam",
            "linkedin": "https://www.linkedin.com/in/minh-phuc-774110229/",
            "github": "https://github.com/phuckhoa33"
        },
        "projects": [
            {"title": "Horserace — JP Horse-Racing Betting Platform", "company": "FPT Software", "period": "6/2026 — Present", "content": "Authored layered system design: API Gateway → BFF → Domain REST API → PostgreSQL with dedicated Spring Batch tier for settlement and reporting.\nBuilt Spring Boot 3.4 BFF modules — request validation, JP/EN i18n, cursor pagination, and SpringDoc OpenAPI for partner integration.\nDesigned batch jobs for daily reconciliation and payout reports with idempotent execution and failure recovery.\nTech: Java 17, Spring Boot 3.4, Spring Batch, PostgreSQL, Gradle"},
            {"title": "Destu Project (Chugai) — Software Engineer", "company": "FPT Software", "period": "3/2026 — Present", "content": "Developed AEM Cloud components, OSGi servlets, and workflow models for pharmaceutical content delivery to JP market.\nImplemented Author→Publish REST sync with JWT auth for regulated content propagation across environments.\nCollaborated with 50-member squad on AEM Enterprise→Cloud migration and component standardization.\nTech: AEM Cloud, Java, Sling, Workflows"},
            {"title": "Vietnam Airline Ticket Application — Software Engineer", "company": "FPT Software", "period": "9/2025 — 4/2026", "content": "Integrated Algolia search on AEM publish tier — indexing, query tuning, and fallback for global ticket search.\nBuilt HTL components, editable templates, and Sling servlets for search results and filter facets.\nCoordinated with 150-member program on content model alignment and publish-tier performance.\nTech: AEM 6.5, Algolia, Java, HTL"},
            {"title": "Canon Bundle Project (Nw3s) — Software Engineer", "company": "FPT Software", "period": "3/2025 — 10/2025", "content": "Led Spring Boot 2→3 and Java 7→11 migration for product bundle workflows serving enterprise print catalog.\nBuilt FTP/SFTP→XML→XSL→AEM Content Fragment pipeline with validation, error queues, and audit logging.\nExposed GraphQL and Elasticsearch endpoints for bundle search; deployed services on GCP Cloud Run.\nTech: Spring Boot 3, AEM, GCP Cloud Run, PostgreSQL"},
            {"title": "Tini Coworking — Space Management Platform", "company": "DHA Corporation + Tini Group (Techheart)", "period": "6/2024 — 3/2025", "content": "Architected dual Spring Boot backends (Admin/User) on MongoDB with role-based API separation and Docker VPS deployment.\nIntegrated IoT gateway for smart locks, AC, cameras, and RFID parking — unified device command API.\nImplemented RabbitMQ workers for booking lifecycle, device events, and async notifications at scale.\nTech: Java, Spring Boot, MongoDB, RabbitMQ, Docker"},
            {"title": "Tini Trade — Trading Platform", "company": "DHA Corporation + Tini Group (Techheart)", "period": "4/2024 — 5/2024", "content": "Delivered dual Spring Boot APIs for market listings, order placement, and portfolio tracking on MongoDB.\nBuilt RabbitMQ settlement pipeline with retry policies and dead-letter handling for trade confirmation.\nContainerized services with Docker and documented REST contracts for mobile client integration.\nTech: Java, Spring Boot, MongoDB, RabbitMQ, Docker"},
            {"title": "Flow Diagram Builder — Full-stack SaaS Tool", "company": "Tech SaaS Cloud Innovations (Odisha, India)", "period": "2022 — 2023", "content": "Built drag-and-drop flow editor with React Flow and persisted diagram graphs via Node.js REST API.\nImplemented versioning, export (PNG/SVG), and collaborative editing hooks for multi-user workspaces.\nDeployed on Ubuntu/AWS with PostgreSQL persistence and CI pipeline for frontend/backend releases.\nTech: Next.js, React Flow, Node.js, PostgreSQL"}
        ]
        }'::jsonb,
        updated_at = NOW()
    WHERE user_id = admin_id AND type = 'work_cv_document' AND status = 'active';

    UPDATE entities
    SET metadata = metadata || jsonb_build_object('blocks', '[]'::jsonb)
    WHERE user_id = admin_id
      AND type = 'work_cv_template'
      AND status = 'active'
      AND COALESCE(metadata->>'is_system', 'false') = 'true';

    RAISE NOTICE 'CV project descriptions refreshed for %', career_owner_email;
END $$;
