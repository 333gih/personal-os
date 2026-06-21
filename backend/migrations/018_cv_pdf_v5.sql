-- CV content aligned with Software-Engineer-v5-1.pdf (layout + text)
-- psql $DATABASE_URL -f migrations/018_cv_pdf_v5.sql

DO $$
DECLARE
    admin_id UUID;
    career_owner_email TEXT := 'mphuc8671@gmail.com';
BEGIN
    SELECT id INTO admin_id FROM users
    WHERE lower(trim(email)) = lower(trim(career_owner_email))
    LIMIT 1;

    IF admin_id IS NULL THEN
        RAISE NOTICE 'Career owner % not found — skip CV v5 update', career_owner_email;
        RETURN;
    END IF;

    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status) VALUES
    ('a000000a-0001-4001-8001-000000000001'::uuid, admin_id, 'work_cv_document', 'CV — Nguyen Khoa Minh Phuc — Software Engineer',
     'Software Engineer specializing in Java, AEM, and Spring Boot, with expertise in scalable backend systems, API integrations, and performance optimization. Experienced in integrating AI tools and LLM-based capabilities into enterprise applications. Proficient in SOLID principles, design patterns, multithreading, cloud deployments, CI/CD, and Docker.',
     '["cv","ideal","transfer"]'::jsonb, 'cv_system',
     '{
        "variant": "ideal",
        "headline": "Nguyen Khoa Minh Phuc — Software Engineer",
        "summary": "Software Engineer specializing in Java, AEM, and Spring Boot, with expertise in scalable backend systems, API integrations, and performance optimization. Experienced in integrating AI tools and LLM-based capabilities into enterprise applications. Proficient in SOLID principles, design patterns, multithreading, cloud deployments, CI/CD, and Docker.",
        "contact": {
            "email": "phuckhoa81@gmail.com",
            "phone": "+(84) 972495038",
            "location": "Ho Chi Minh City",
            "linkedin": "linkedin.com",
            "github": "github.com"
        },
        "primary_stack": ["Java", "Spring Boot", "AEM"],
        "years_experience": 3.5,
        "skill_groups": [
            {"category": "Backend & APIs", "items": ["Java (Spring Boot, AEM)", "Node.js (NestJS)", "Golang", "gRPC", "WebSocket"]},
            {"category": "Frontend", "items": ["ReactJS", "NextJS", "Thymeleaf", "HTL"]},
            {"category": "Database & Caching", "items": ["PostgreSQL", "MySQL", "Oracle", "MongoDB", "Redis"]},
            {"category": "Search Engine", "items": ["ElasticSearch", "Algolia"]},
            {"category": "AI & Tooling", "items": ["GitHub Copilot", "Cursor AI", "Claude AI", "ChatGPT (for code generation, review & test writing); experience integrating AI tools and LLM-based capabilities into delivery workflows"]},
            {"category": "Scalability & Performance", "items": ["Microservices", "Kafka", "RabbitMQ", "Distributed Systems"]},
            {"category": "Cloud", "items": ["Google Cloud", "AEM Cloud"]}
        ],
        "education": [
            {"school": "Ho Chi Minh Open University (OU)", "period": "Present", "content": "Pursuing a Bachelor''s degree in Information Technology."},
            {"school": "FPT Polytechnic College", "period": "Graduated", "content": "Graduated with a strong foundation in software development and engineering principles."}
        ],
        "achievements": [
            {"content": "Delivered and optimized large-scale backend systems handling millions of records with high performance and reliability."},
            {"content": "Designed and maintained scalable architectures across multiple services, ensuring stability under heavy load."}
        ],
        "certificates": [
            {"title": "CodeGym Certification", "issuer": "Obtained a technical certification in software development."},
            {"title": "Coursera Certifications", "issuer": "Completed multiple courses on software development and database management."},
            {"title": "Google Certifications", "issuer": "Acquired certifications in modern technologies and best practices."}
        ],
        "experience": [
            {
                "title": "Software Engineer",
                "company": "FPT Software",
                "period": "2025 — Now",
                "content": "Develop, migrate, and customize Spring Boot services and AEM components, templates, and workflows for enterprise applications.\nDesign and implement scalable, high-performance Java microservices.\nApply SOLID principles, design patterns to ensure efficiency and maintainability.\nOptimize performance, caching (Redis, CDN, AEM Dispatcher).\nBuild and maintain RESTful APIs, GraphQL, and third-party integrations.\nWork with CI/CD, Docker, and cloud platforms (GCP).\nApplied AI-powered solutions with OpenAI API to improve product capabilities for the Canon Bundle Application."
            },
            {
                "title": "Middle Developer cum Backend Lead",
                "company": "DHA Corporation + Tini Group (Techheart)",
                "period": "2024 — 2025",
                "content": "Led backend development, optimizing and maintaining large-scale product systems.\nDesigned and implemented scalable APIs, CI/CD pipelines.\nCollaborated with Web and Mobile teams to resolve deployment challenges and enhance system performance.\nProvided mentorship and training for new developers.\nUsed AI tools (ChatGPT, Copilot) to generate boilerplate code and unit test templates, reducing repetitive work for the team.\nIntegrated third-party smart device APIs, including smart door locks and air conditioner systems, printer, into product development."
            },
            {
                "title": "Junior Backend Developer",
                "company": "Tech SaaS Cloud Innovations (Odisha, India)",
                "period": "2023 — 2024",
                "content": "Developed and maintained full-stack applications with seamless backend-frontend integration.\nCollaborated with stakeholders to translate business needs into technical solutions.\nDeployed and optimized applications on Ubuntu servers and Cloud Provider (AWS) for reliability and scalability.\nAuthored technical documentation to support development and maintenance."
            }
        ],
        "projects": [
            {
                "title": "Canon Bundle Project (Nw3s) — Software Engineer",
                "company": "FPT Software",
                "period": "3/2025 — 10/2025",
                "content": "Migrated Spring Boot 2 to 3 and upgraded Java 7 to 11.\nIntegrated Spring Boot workflows with AEM and Content Fragment processing.\nDeveloped workflow portals and improved system maintainability.\nIntegrated PostgreSQL, GraphQL, and Elasticsearch into enterprise workflows.\nTech: Spring Boot, AEM, Oracle, PostgreSQL, GCP, ElasticSearch | Team Size: 135"
            },
            {
                "title": "Vietnam Airline Ticket Application — Software Engineer",
                "company": "FPT Software",
                "period": "9/2025 — 4/2026",
                "content": "Developed search features using Algolia Search.\nDesigned AEM components, templates, and servlets for search functionality.\nCollaborated with teams to synchronize data across the system.\nImproved maintainability and scalability of search implementations.\nTech: AEM, Algolia | Team Size: 150"
            },
            {
                "title": "Destu Project (Chugai) — Software Engineer",
                "company": "FPT Software",
                "period": "3/2026 — Present",
                "content": "Developed AEM components, templates, and servlets for enterprise solutions.\nCollaborated with Japanese clients to improve legacy workflows and requirements.\nSupported migration from AEM Enterprise to AEM Cloud.\nOptimized component reusability and maintainability.\nTech: AEM Cloud, Probo | Team Size: 50"
            }
        ]
     }'::jsonb,
     'work', 'active')
    ON CONFLICT (id) DO UPDATE SET
        title = EXCLUDED.title,
        content = EXCLUDED.content,
        metadata = EXCLUDED.metadata,
        updated_at = NOW();

    RAISE NOTICE 'CV v5 PDF content updated for %', career_owner_email;
END $$;
