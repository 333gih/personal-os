-- Update ideal CV to two-column template with categorized skills (matches CV sample layout)
-- psql $DATABASE_URL -f migrations/016_cv_template_v2.sql

DO $$
DECLARE
    admin_id UUID;
    career_owner_email TEXT := 'mphuc8671@gmail.com';
BEGIN
    SELECT id INTO admin_id FROM users
    WHERE lower(trim(email)) = lower(trim(career_owner_email))
    LIMIT 1;

    IF admin_id IS NULL THEN
        RAISE NOTICE 'Career owner % not found — skip CV template update', career_owner_email;
        RETURN;
    END IF;

    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status) VALUES
    ('a000000a-0001-4001-8001-000000000001'::uuid, admin_id, 'work_cv_document', 'CV — Nguyen Khoa Minh Phuc — Software Engineer',
     'Software Engineer specializing in Java, AEM, and Spring Boot with expertise in building scalable backend systems, API integrations, and performance optimization. Proficient in SOLID principles, design patterns, multithreading, cloud deployments, CI/CD, and Docker. Integrates AI tools and LLM-based capabilities into delivery workflows.',
     '["cv","ideal","transfer"]'::jsonb, 'cv_system',
     '{
        "variant": "ideal",
        "headline": "Nguyen Khoa Minh Phuc — Software Engineer",
        "summary": "Software Engineer specializing in Java, AEM, and Spring Boot with expertise in building scalable backend systems, API integrations, and performance optimization. Proficient in SOLID principles, design patterns, multithreading, cloud deployments, CI/CD, and Docker. Integrates AI tools and LLM-based capabilities into delivery workflows.",
        "contact": {
            "email": "mphuc8671@gmail.com",
            "phone": "",
            "location": "Ho Chi Minh City, Vietnam",
            "linkedin": "",
            "github": ""
        },
        "primary_stack": ["Java", "Spring Boot", "AEM"],
        "years_experience": 3.5,
        "skill_groups": [
            {"category": "Backend & APIs", "items": ["Java (Spring Boot, AEM)", "Node.js (NestJS)", "Golang", "gRPC", "WebSocket"]},
            {"category": "Frontend", "items": ["ReactJS", "NextJS", "Thymeleaf", "HTL"]},
            {"category": "Database & Caching", "items": ["PostgreSQL", "MySQL", "Oracle", "MongoDB", "Redis"]},
            {"category": "Search Engine", "items": ["ElasticSearch", "Algolia"]},
            {"category": "AI & Tooling", "items": ["GitHub Copilot", "Cursor AI", "Claude AI", "ChatGPT"]},
            {"category": "Scalability & Performance", "items": ["Microservices", "Kafka", "RabbitMQ", "Distributed Systems"]},
            {"category": "Cloud", "items": ["Google Cloud", "AEM Cloud"]}
        ],
        "skills": ["Java (Spring Boot, AEM)", "Node.js (NestJS)", "Golang", "gRPC", "WebSocket", "ReactJS", "NextJS", "Thymeleaf", "HTL", "PostgreSQL", "MySQL", "Oracle", "MongoDB", "Redis", "ElasticSearch", "Algolia", "GitHub Copilot", "Cursor AI", "Claude AI", "ChatGPT", "Microservices", "Kafka", "RabbitMQ", "Distributed Systems", "Google Cloud", "AEM Cloud"],
        "education": [
            {"school": "Ho Chi Minh Open University (OU)", "degree": "Bachelor of Information Technology", "period": "Present", "content": "Currently pursuing degree in Information Technology."},
            {"school": "FPT Polytechnic College", "degree": "Software Development Foundation", "period": "Graduated", "content": "Foundation in software development and engineering practices."}
        ],
        "certificates": [
            {"title": "Full-stack Java Developer", "issuer": "CodeGym"},
            {"title": "Software Development & Database Management", "issuer": "Coursera"},
            {"title": "Google Cloud & Professional Certificates", "issuer": "Google"}
        ],
        "experience": [
            {"title": "Software Engineer", "company": "FPT Software", "period": "2025 — Present", "content": "Spring Boot services and AEM components for enterprise clients.\nJava microservices, performance caching (Redis, CDN, AEM Dispatcher).\nCI/CD on GCP; OpenAI API integration for product capabilities."},
            {"title": "Middle Developer cum Backend Lead", "company": "DHA Corporation + Tini Group", "period": "2024 — 2025", "content": "Led backend development and optimized large-scale systems.\nDesigned CI/CD pipelines; IoT smart-device API integrations.\nUsed AI tools (ChatGPT, Copilot) for boilerplate and code review."},
            {"title": "Junior Backend Developer", "company": "Tech SaaS Cloud Innovations (India)", "period": "2023 — 2024", "content": "Full-stack application development.\nAWS/Ubuntu server deployment and technical documentation."}
        ],
        "projects": [
            {"title": "Destu Project (Chugai)", "company": "FPT Software", "period": "3/2026 — Present", "content": "AEM components and collaboration with Japanese client stakeholders.\nAEM 6.5 to AEM Cloud migration (Probo). Team size: 50."},
            {"title": "Canon NW3S — Documentum to AEM Migration", "company": "FPT Software", "period": "2025", "content": "FTP→XML→XSL→AEM workflow, Content Fragments, Spring Boot 3, GCP Cloud Run, Elasticsearch SEO."},
            {"title": "Vietnam Airlines — Algolia Global Search", "company": "FPT Software", "period": "2025 — 2026", "content": "Publish workflow indexes CF + FAQ + components to Algolia; reusable cross-team search pattern."},
            {"title": "Tini Coworking — Space Management Platform", "company": "TINI GROUP", "period": "2024 — 2025", "content": "Dual NestJS backends, IoT gateway, MongoDB, RabbitMQ async processing."}
        ]
     }'::jsonb,
     'work', 'active')
    ON CONFLICT (id) DO UPDATE SET
        title = EXCLUDED.title,
        content = EXCLUDED.content,
        metadata = EXCLUDED.metadata,
        updated_at = NOW();

    RAISE NOTICE 'CV template v2 updated for %', career_owner_email;
END $$;
