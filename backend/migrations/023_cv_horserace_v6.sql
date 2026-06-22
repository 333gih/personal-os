-- CV v6: Horserace system design + Tini Trade/Coworking + balanced two-column layout
-- psql $DATABASE_URL -f migrations/023_cv_horserace_v6.sql

DO $$
DECLARE
    admin_id UUID;
    career_owner_email TEXT := 'mphuc8671@gmail.com';
BEGIN
    SELECT id INTO admin_id FROM users
    WHERE lower(trim(email)) = lower(trim(career_owner_email))
    LIMIT 1;

    IF admin_id IS NULL THEN
        RAISE NOTICE 'Career owner % not found — skip CV v6 update', career_owner_email;
        RETURN;
    END IF;

    -- ── Horserace work project (JP horse-racing betting platform)
    UPDATE entities SET
        title = 'Horserace — JP Horse-Racing Betting Platform',
        content = 'Japanese horse-racing betting platform at FPT Software. Multi-tier architecture: Client → Frontend (Next.js) → API Gateway → NLB → Screen API BFF → ALB → Domain API → PostgreSQL, with Spring Batch for overnight settlement and reporting. Contributed to application architecture overview and layered designs for front-end (Atomic Design), BFF, REST API, and batch modules.',
        tags = '["fpt","horserace","japan","betting","spring-boot","nextjs"]'::jsonb,
        metadata = metadata || '{
            "company": "FPT Software",
            "role": "Software Engineer",
            "start_date": "2026-06-01",
            "end_date": null,
            "status": "active",
            "priority": "primary",
            "has_design_system": true,
            "design_images": [
                "/work/design/horserace-app-architecture.png",
                "/work/design/horserace-frontend-logical.png",
                "/work/design/horserace-bff-api-batch.png"
            ],
            "architecture_layers": [
                {"layer": "Client & Edge", "nodes": ["Web Client", "Frontend (Next.js 15 / React 19)", "API Gateway", "NLB", "ALB"]},
                {"layer": "Screen API (BFF)", "nodes": ["API Controller", "Business Service", "Request/Response templates", "Pagination", "Error templates"]},
                {"layer": "Domain API", "nodes": ["REST Controllers", "Business Services", "Base Controller", "Spring Security", "SpringDoc OpenAPI"]},
                {"layer": "Batch (Spring Batch)", "nodes": ["Job/Step Configuration", "Base Reader/Processor/Writer/Tasklet", "Abstract Job Execution Listener"]},
                {"layer": "Cross-cutting", "nodes": ["Validation", "Exception handling", "i18n", "Cache", "Log/Message management"]},
                {"layer": "Persistence", "nodes": ["PostgreSQL", "Batch job repository"]}
            ],
            "stack": [
                "Java 17", "Spring Boot 3.4", "Spring Batch", "Spring Security", "SpringDoc OpenAPI",
                "TypeScript 5.7", "React 19", "Next.js 15", "Redux Toolkit", "React Hook Form", "Yup",
                "Axios", "MSW", "Vite", "Jest", "Storybook", "Gradle", "Log4j2", "Lombok"
            ]
        }'::jsonb,
        updated_at = NOW()
    WHERE id = 'a0000004-0001-4001-8001-000000000001'::uuid;

    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status) VALUES
    ('a0000006-0001-4001-8001-000000000008'::uuid, admin_id, 'work_design_doc', 'Horserace — Application Architecture Overview',
     'Client → Frontend → API Gateway → NLB → Screen API BFF → ALB → Domain API → Database. Separate Batch tier for scheduled jobs. AWS-style deployment with gateway-terminated traffic.',
     '["horserace","architecture","fpt","japan"]', 'career_seed',
     '{"project_id":"a0000004-0001-4001-8001-000000000001","image":"/work/design/horserace-app-architecture.png","doc_type":"architecture","has_design_system":true,
       "architecture_layers":[
         {"layer":"Traffic","nodes":["Client","Frontend","API Gateway","NLB","ALB"]},
         {"layer":"Application","nodes":["Screen API BFF","Domain API","Batch"]},
         {"layer":"Data","nodes":["PostgreSQL"]}
       ]}'::jsonb, 'work', 'active'),
    ('a0000006-0001-4001-8001-000000000009'::uuid, admin_id, 'work_design_doc', 'Horserace — Front-end Logical View',
     'Next.js + React 19 with Atomic Design (Atoms/Molecules/Organisms/Templates). Redux Toolkit global state, react-router-dom, React Hook Form + Yup, i18next, Axios + MSW mocks, Vite build, Jest + Testing Library, Storybook UI catalog.',
     '["horserace","frontend","nextjs","react"]', 'career_seed',
     '{"project_id":"a0000004-0001-4001-8001-000000000001","image":"/work/design/horserace-frontend-logical.png","doc_type":"architecture","has_design_system":true,
       "architecture_layers":[
         {"layer":"UI Catalog","nodes":["Storybook","Atoms","Molecules","Organisms","Templates","Base Layout"]},
         {"layer":"Screens","nodes":["HTML5 layouts","SCSS/CSS Modules","TypeScript","React Hooks"]},
         {"layer":"State & Forms","nodes":["Redux Toolkit","React Hook Form","Yup","react-router-dom"]},
         {"layer":"Integration","nodes":["Axios","MSW","i18next","IndexedDB cache","Day.js","Lodash"]},
         {"layer":"Quality","nodes":["ESLint","Prettier","Stylelint","Jest","Vite"]}
       ]}'::jsonb, 'work', 'active'),
    ('a0000006-0001-4001-8001-000000000010'::uuid, admin_id, 'work_design_doc', 'Horserace — BFF, API & Batch Logical Views',
     'Layered Java services: Screen API (BFF) for front-end tailored endpoints; Domain API with request/response templates and pagination; Spring Batch with base Reader/Processor/Writer/Tasklet abstractions and job listeners. Shared common module for validation, exception handling, i18n, and cache.',
     '["horserace","bff","spring-batch","api"]', 'career_seed',
     '{"project_id":"a0000004-0001-4001-8001-000000000001","image":"/work/design/horserace-bff-api-batch.png","doc_type":"architecture","has_design_system":true,
       "architecture_layers":[
         {"layer":"Screen API (BFF)","nodes":["API Controller","Business Service"]},
         {"layer":"System Based","nodes":["Request template","Response template","Base Controller","Pagination","Error template"]},
         {"layer":"Batch","nodes":["Job Configuration","Step Configuration","Base Reader","Base Processor","Base Writer","Base Tasklet","Job Execution Listener"]},
         {"layer":"Framework","nodes":["Spring Boot 3.4","Spring Security","Spring Batch","SpringDoc OpenAPI","Log4j2","Lombok"]},
         {"layer":"Common","nodes":["Validation","Exception handling","i18n","Cache","Constants","Utilities"]}
       ]}'::jsonb, 'work', 'active')
    ON CONFLICT (id) DO UPDATE SET
        title = EXCLUDED.title,
        content = EXCLUDED.content,
        tags = EXCLUDED.tags,
        metadata = EXCLUDED.metadata,
        updated_at = NOW();

    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status) VALUES
    ('a0000005-0001-4001-8001-000000000009'::uuid, admin_id, 'work_feature', 'Horserace: Layered BFF + Domain API + Batch',
     'Standardized request/response templates, pagination, and error contracts across Screen API BFF and Domain API; Spring Batch base classes for settlement/report jobs.',
     '["horserace","architecture","spring-boot"]', 'career_seed',
     '{"project_id":"a0000004-0001-4001-8001-000000000001"}'::jsonb, 'work', 'active')
    ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, content = EXCLUDED.content, updated_at = NOW();

    -- ── CV document v6 (balanced columns: richer left skills/achievements; right = FPT + TINI projects)
    UPDATE entities SET
        title = 'CV — Nguyen Khoa Minh Phuc — Software Engineer',
        content = 'Software Engineer specializing in Java/Spring Boot and enterprise front-end (Next.js/React). Experienced in layered system design, BFF patterns, batch processing, AEM, and scalable API integrations.',
        metadata = '{
        "variant": "ideal",
        "headline": "Nguyen Khoa Minh Phuc — Software Engineer",
        "summary": "Software Engineer specializing in Java, Spring Boot, and Next.js/React front-ends, with expertise in scalable backend systems, BFF/API layering, and batch processing. Experienced in Japanese enterprise delivery (Horserace betting platform), AEM migrations, and IoT SaaS platforms. Proficient in SOLID principles, design patterns, CI/CD, Docker, and AI-assisted development.",
        "contact": {
            "email": "phuckhoa81@gmail.com",
            "phone": "+(84) 972495038",
            "location": "Ho Chi Minh City",
            "linkedin": "linkedin.com",
            "github": "github.com"
        },
        "primary_stack": ["Java", "Spring Boot 3", "Next.js", "TypeScript", "AEM"],
        "years_experience": 3.5,
        "skill_groups": [
            {"category": "Backend & APIs", "items": ["Java (Spring Boot 3.4, Spring Batch, Spring Security)", "NestJS", "Golang", "gRPC", "REST/BFF layering", "SpringDoc OpenAPI"]},
            {"category": "Frontend", "items": ["TypeScript", "React 19", "Next.js 15", "Redux Toolkit", "React Hook Form", "Storybook", "AEM HTL", "Atomic Design"]},
            {"category": "Horserace / JP Enterprise", "items": ["API Gateway + NLB/ALB topology", "Screen API BFF pattern", "Spring Batch (Reader/Processor/Writer)", "MSW + Axios", "i18next", "Vite/Jest"]},
            {"category": "Database & Caching", "items": ["PostgreSQL", "MySQL", "Oracle", "MongoDB", "Redis"]},
            {"category": "Search & Cloud", "items": ["ElasticSearch", "Algolia", "Google Cloud", "AEM Cloud", "Docker", "CI/CD"]},
            {"category": "AI & Tooling", "items": ["GitHub Copilot", "Cursor AI", "Claude AI", "ChatGPT for code review and test generation"]}
        ],
        "education": [
            {"school": "Ho Chi Minh Open University (OU)", "period": "Present", "content": "Pursuing a Bachelor''s degree in Information Technology."},
            {"school": "FPT Polytechnic College", "period": "Graduated", "content": "Strong foundation in software development and engineering principles."}
        ],
        "achievements": [
            {"content": "Authored layered system designs for Horserace (JP betting): front-end Atomic Design, BFF, Domain API, and Spring Batch modules."},
            {"content": "Delivered and optimized large-scale backend systems handling millions of records with high performance and reliability."},
            {"content": "Led NestJS backend and IoT integrations at TINI Group — dual-stack platforms with RabbitMQ async processing."},
            {"content": "Designed and maintained scalable microservice-style architectures across AEM, Spring Boot, and Node.js stacks."}
        ],
        "certificates": [
            {"title": "CodeGym Certification", "issuer": "Technical certification in software development."},
            {"title": "Coursera Certifications", "issuer": "Software development and database management courses."},
            {"title": "Google Certifications", "issuer": "Modern cloud technologies and best practices."}
        ],
        "experience": [
            {
                "title": "Software Engineer",
                "company": "FPT Software",
                "period": "2025 — Now",
                "content": "Enterprise delivery for Japanese clients: Horserace betting platform system design, AEM + Spring Boot services.\nLayered BFF/API/batch architecture, performance optimization, CI/CD on GCP.\nAEM components, Content Fragments, Algolia search, and Spring Boot 3 migrations."
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
                "content": "Full-stack applications with backend–frontend integration.\nDeployed on Ubuntu/AWS; technical documentation for maintenance."
            }
        ],
        "projects": [
            {
                "title": "Horserace — JP Horse-Racing Betting Platform",
                "company": "FPT Software",
                "period": "6/2026 — Present",
                "content": "System design: Client → Frontend (Next.js 15/React 19) → API Gateway → BFF → Domain API → PostgreSQL + Batch tier.\nFront-end: Atomic Design, Redux Toolkit, React Hook Form/Yup, Storybook, MSW, Vite/Jest.\nBack-end: Spring Boot 3.4 layered modules — BFF, REST API, Spring Batch (base Reader/Processor/Writer).\nTech: Java, Spring Boot 3.4, Spring Batch, TypeScript, Next.js 15, PostgreSQL, Gradle"
            },
            {
                "title": "Destu Project (Chugai) — Software Engineer",
                "company": "FPT Software",
                "period": "3/2026 — Present",
                "content": "AEM Cloud components and content sync Author → +CAS via REST API.\nJapanese client collaboration; Probo migration support.\nTech: AEM Cloud, Java, Sling | Team: 50"
            },
            {
                "title": "Vietnam Airline Ticket Application — Software Engineer",
                "company": "FPT Software",
                "period": "9/2025 — 4/2026",
                "content": "Algolia global search on AEM publish workflow.\nCross-team CF + FAQ + component indexing pattern.\nTech: AEM, Algolia, Java | Team: 150"
            },
            {
                "title": "Canon Bundle Project (Nw3s) — Software Engineer",
                "company": "FPT Software",
                "period": "3/2025 — 10/2025",
                "content": "Spring Boot 2→3, Java 7→11; FTP→XML→AEM Content Fragment pipeline.\nGraphQL + Elasticsearch; GCP Cloud Run.\nTech: Spring Boot 3, AEM, PostgreSQL | Team: 135"
            },
            {
                "title": "Tini Coworking — Space Management Platform",
                "company": "DHA Corporation + Tini Group (Techheart)",
                "period": "6/2024 — 3/2025",
                "content": "Dual NestJS backends (Admin/User), Next.js web, mobile app, MongoDB on Docker VPS.\nIoT gateway: smart locks, AC, cameras, printers, RFID parking.\nNFT room listing; RabbitMQ async workers.\nTech: NestJS, Next.js, MongoDB, RabbitMQ, Docker"
            },
            {
                "title": "Tini Trade — Trading Platform",
                "company": "DHA Corporation + Tini Group (Techheart)",
                "period": "4/2024 — 5/2024",
                "content": "Dual NestJS backends with Next.js Admin/User frontends and mobile app.\nMarket listing, orders, portfolio; RabbitMQ for settlement and alerts.\nTech: NestJS, React, MongoDB, RabbitMQ, Docker"
            }
        ]
     }'::jsonb,
        updated_at = NOW()
    WHERE id = 'a000000a-0001-4001-8001-000000000001'::uuid AND user_id = admin_id;

    RAISE NOTICE 'CV v6 Horserace + TINI projects updated for %', career_owner_email;
END $$;
