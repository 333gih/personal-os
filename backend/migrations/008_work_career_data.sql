-- Career data for Nguyen Khoa Minh Phuc — Personal OS work domain
-- Run after 002_seed_data: psql $DATABASE_URL -f migrations/008_work_career_data.sql
-- Idempotent: uses fixed UUIDs and ON CONFLICT DO UPDATE

DO $$
DECLARE
    admin_id UUID;
BEGIN
    SELECT id INTO admin_id FROM users WHERE email = 'admin@personal-os.local' LIMIT 1;
    IF admin_id IS NULL THEN
        RAISE NOTICE 'No admin user found. Start the API first to create default user.';
        RETURN;
    END IF;

    -- Remove placeholder work seed from 002
    DELETE FROM relationships r
    USING entities e
    WHERE r.source_entity_id = e.id AND e.domain = 'work' AND e.source IN ('fash', 'work', 'seed');
    DELETE FROM relationships r
    USING entities e
    WHERE r.target_entity_id = e.id AND e.domain = 'work' AND e.source IN ('fash', 'work', 'seed');
    DELETE FROM entities
    WHERE domain = 'work' AND source IN ('fash', 'work', 'seed')
      AND title IN (
        'Marketplace Platform', 'Redis', 'Kafka', 'Catalog Performance Issue',
        'Use Redis for Catalog Cache', 'Always Load Test Before Launch'
      );

    -- Career profile
    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status)
    VALUES (
        'a0000001-0001-4001-8001-000000000001'::uuid, admin_id, 'work_project',
        'Nguyen Khoa Minh Phuc — Career Profile',
        'Software Engineer specializing in Java, AEM, and Spring Boot with scalable backend systems, API integrations, and performance optimization. Background in NestJS/Node.js (TINI Group), transitioned to enterprise AEM + Spring Boot at FPT Software. Core hours: 08:00–17:00 ICT for focused delivery.',
        '["career","profile","aem","spring-boot","nestjs"]',
        'career_seed',
        '{"kind":"profile","name":"Nguyen Khoa Minh Phuc","email":"phuckhoa81@gmail.com","location":"Ho Chi Minh City","work_hours":"08:00-17:00","timezone":"Asia/Ho_Chi_Minh","current_title":"Senior Software Engineer","current_company":"FPT Software"}'::jsonb,
        'work', 'active'
    ) ON CONFLICT (id) DO UPDATE SET
        title = EXCLUDED.title, content = EXCLUDED.content, tags = EXCLUDED.tags,
        metadata = EXCLUDED.metadata, updated_at = NOW();

    -- Employers
    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status) VALUES
    ('a0000002-0001-4001-8001-000000000001'::uuid, admin_id, 'work_employer', 'FPT Software',
     'Enterprise software — AEM, Spring Boot, Java microservices for global clients (Canon, Vietnam Airlines, Chugai).',
     '["fpt","enterprise","aem"]', 'career_seed',
     '{"website":"https://fptsoftware.com","location":"Hybrid"}'::jsonb, 'work', 'active'),
    ('a0000002-0001-4001-8001-000000000002'::uuid, admin_id, 'work_employer', 'TINI GROUP',
     'Techheart product company — coworking space management and trading platforms.',
     '["tini","saas","coworking"]', 'career_seed',
     '{"location":"Ho Chi Minh City"}'::jsonb, 'work', 'active'),
    ('a0000002-0001-4001-8001-000000000003'::uuid, admin_id, 'work_employer', 'Tech Saas Cloud Innovations',
     'Remote SaaS startup (Odisha, India) — full-stack product development.',
     '["saas","remote","india"]', 'career_seed',
     '{"location":"Odisha, India · Remote"}'::jsonb, 'work', 'active'),
    ('a0000002-0001-4001-8001-000000000004'::uuid, admin_id, 'work_employer', 'Upword Foundation',
     'Freelance nonprofit/edtech projects in Vietnam.',
     '["freelance","nonprofit"]', 'career_seed',
     '{"location":"Vietnam · Remote"}'::jsonb, 'work', 'active')
    ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, content = EXCLUDED.content,
        metadata = EXCLUDED.metadata, updated_at = NOW();

    -- Roles
    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status) VALUES
    ('a0000003-0001-4001-8001-000000000001'::uuid, admin_id, 'work_role', 'Senior Software Engineer @ FPT Software',
     'Develop, migrate, and customize Spring Boot services and AEM components. GCP, CI/CD, GraphQL, Elasticsearch, Algolia integrations.',
     '["senior","aem","spring-boot"]', 'career_seed',
     '{"company":"FPT Software","role":"Senior Software Engineer","start_date":"2025-03-01","end_date":null,"status":"active","location":"Hybrid","employer_id":"a0000002-0001-4001-8001-000000000001"}'::jsonb,
     'work', 'active'),
    ('a0000003-0001-4001-8001-000000000002'::uuid, admin_id, 'work_role', 'Backend Lead @ TINI GROUP',
     'Led backend team, NestJS APIs, Docker on Ubuntu VPS, MongoDB, third-party IoT (doors, AC, cameras, printers, RFID).',
     '["backend-lead","nestjs","iot"]', 'career_seed',
     '{"company":"TINI GROUP","role":"Backend Lead","start_date":"2024-06-01","end_date":"2025-03-01","status":"completed","location":"District 1, HCMC","employer_id":"a0000002-0001-4001-8001-000000000002"}'::jsonb,
     'work', 'active'),
    ('a0000003-0001-4001-8001-000000000003'::uuid, admin_id, 'work_role', 'Junior Software Engineer @ TINI GROUP',
     'NestJS + ReactJS backend development for Tini Trade.',
     '["junior","nestjs","mongodb"]', 'career_seed',
     '{"company":"TINI GROUP","role":"Junior Software Engineer","start_date":"2024-04-01","end_date":"2024-05-31","status":"completed","location":"Binh Thanh, HCMC","employer_id":"a0000002-0001-4001-8001-000000000002"}'::jsonb,
     'work', 'active'),
    ('a0000003-0001-4001-8001-000000000004'::uuid, admin_id, 'work_role', 'Fresher Backend Developer @ Tech Saas Cloud Innovations',
     'Full-stack apps, Ubuntu/AWS deployment, technical documentation.',
     '["fresher","nodejs","aws"]', 'career_seed',
     '{"company":"Tech Saas Cloud Innovations","role":"Fresher Backend Developer","start_date":"2022-01-01","end_date":"2023-12-31","status":"completed","location":"India · Remote","employer_id":"a0000002-0001-4001-8001-000000000003"}'::jsonb,
     'work', 'active'),
    ('a0000003-0001-4001-8001-000000000005'::uuid, admin_id, 'work_role', 'Freelancer Developer @ Upword Foundation',
     'Remote freelance development for foundation projects.',
     '["freelance"]', 'career_seed',
     '{"company":"Upword Foundation","role":"Freelancer Developer","start_date":"2021-01-01","end_date":"2022-12-31","status":"completed","location":"Vietnam · Remote","employer_id":"a0000002-0001-4001-8001-000000000004"}'::jsonb,
     'work', 'active')
    ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, content = EXCLUDED.content,
        metadata = EXCLUDED.metadata, updated_at = NOW();

    -- Projects
    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status) VALUES
    ('a0000004-0001-4001-8001-000000000001'::uuid, admin_id, 'work_project', 'Racehorse — JP Betting Platform',
     'Current FPT project: Japanese horse-racing betting system. Early stage — architecture TBD.',
     '["fpt","current","betting","japan"]', 'career_seed',
     '{"company":"FPT Software","role":"Senior Software Engineer","start_date":"2026-06-01","end_date":null,"status":"active","priority":"primary","team_size":null,"stack":["TBD"]}'::jsonb,
     'work', 'active'),
    ('a0000004-0001-4001-8001-000000000002'::uuid, admin_id, 'work_project', 'Destu (Chugai) — AEM Cloud Migration',
     'Migrate AEM 6.5 to AEM Cloud. AEM components, page workflows, content sync from Author to +CAS via REST API (POST /api/content/sync). Sling models, JWT auth, PostgreSQL/MongoDB persistence.',
     '["aem","aem-cloud","chugai","migration"]', 'career_seed',
     '{"company":"FPT Software","role":"Software Engineer","start_date":"2026-03-01","end_date":null,"status":"active","priority":"primary","team_size":50,"stack":["AEM Cloud","Java","Sling","Workflows","Probo"],"design_images":["/work/design/destu-aem-sync.png"]}'::jsonb,
     'work', 'active'),
    ('a0000004-0001-4001-8001-000000000003'::uuid, admin_id, 'work_project', 'Vietnam Airlines — AEM + Algolia Global Search',
     'Content management on AEM. Built global search: aggregate Content Fragment + FAQ + dynamic page data from cross-team components. Publish workflow auto-indexes to Algolia. Integration middleware for auth and third parties (Amadeus, Gimasys).',
     '["vna","aem","algolia","search"]', 'career_seed',
     '{"company":"FPT Software","role":"Software Engineer","start_date":"2025-09-01","end_date":"2026-04-30","status":"active","priority":"side","team_size":150,"stack":["AEM","Algolia","Java","HTL"],"design_images":["/work/design/vna-architecture.png"]}'::jsonb,
     'work', 'active'),
    ('a0000004-0001-4001-8001-000000000004'::uuid, admin_id, 'work_project', 'Canon NW3S — Documentum to AEM Migration',
     'Bundle B2C/B2B content pipeline: GCP Cloud Run + scheduled jobs pull ZIP from FTP/SFTP, Spring Boot parses XML, XSL preview + action detection (create/update/delete), AEM custom workflow steps with dialogs, Content Fragment creation (troubleshoot, specification, driver-download). Migrated Java 7→11, Spring Boot 2→3, Oracle→PostgreSQL. GraphQL + Elasticsearch for troubleshoot SEO. Thymeleaf server-side portal. Unit test coverage >50%.',
     '["canon","nw3s","aem","spring-boot","gcp","elasticsearch"]', 'career_seed',
     '{"company":"FPT Software","role":"Software Engineer","start_date":"2025-03-01","end_date":"2025-10-31","status":"completed","priority":"primary","team_size":135,"stack":["Spring Boot 3","AEM","GCP Cloud Run","FTP","XSL","PostgreSQL","GraphQL","Elasticsearch","Thymeleaf"],"design_images":["/work/design/nw3s-current-architecture.png","/work/design/nw3s-new-architecture.png","/work/design/nw3s-modules.png"]}'::jsonb,
     'work', 'active'),
    ('a0000004-0001-4001-8001-000000000005'::uuid, admin_id, 'work_project', 'Tini Coworking — Space Management Platform',
     'Room booking and coworking operations. NestJS backend lead: Ubuntu Docker VPS, MongoDB. Integrated smart locks, AC, cameras, printers, RFID cards for parking (monthly/casual).',
     '["tini","coworking","nestjs","iot"]', 'career_seed',
     '{"company":"TINI GROUP","role":"Backend Lead","start_date":"2024-06-01","end_date":"2025-03-01","status":"completed","priority":"primary","stack":["NestJS","React","MongoDB","Docker","Ubuntu"]}'::jsonb,
     'work', 'active'),
    ('a0000004-0001-4001-8001-000000000006'::uuid, admin_id, 'work_project', 'Tini Trade — Trading Platform',
     'First project at TINI. NestJS + ReactJS backend, MongoDB, Docker on Ubuntu VPS.',
     '["tini","trade","nestjs","mongodb"]', 'career_seed',
     '{"company":"TINI GROUP","role":"Junior Software Engineer","start_date":"2024-04-01","end_date":"2024-05-31","status":"completed","stack":["NestJS","React","MongoDB","Docker"]}'::jsonb,
     'work', 'active'),
    ('a0000004-0001-4001-8001-000000000007'::uuid, admin_id, 'work_project', 'Flow Diagram Builder (draw.io-style)',
     'Drag-and-drop flow diagram app similar to draw.io using flow library + Next.js. Built at Tech Saas Cloud Innovations.',
     '["nextjs","flow","diagram","saas"]', 'career_seed',
     '{"company":"Tech Saas Cloud Innovations","role":"Fresher Backend Developer","start_date":"2022-06-01","end_date":"2023-06-30","status":"completed","stack":["Next.js","Node.js"]}'::jsonb,
     'work', 'active')
    ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, content = EXCLUDED.content,
        tags = EXCLUDED.tags, metadata = EXCLUDED.metadata, updated_at = NOW();

    -- Key features (work_feature)
    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status) VALUES
    ('a0000005-0001-4001-8001-000000000001'::uuid, admin_id, 'work_feature', 'NW3S: FTP ZIP → XML Pipeline',
     'GCP Cloud Run scheduled job + API trigger pulls ZIP from FTP/SFTP, unzips XML, Spring Boot batch processing.',
     '["nw3s","ftp","gcp"]', 'career_seed', '{"project_id":"a0000004-0001-4001-8001-000000000004"}'::jsonb, 'work', 'active'),
    ('a0000005-0001-4001-8001-000000000002'::uuid, admin_id, 'work_feature', 'NW3S: AEM Custom Workflow + Content Fragments',
     'Custom Process Step workflows detect create/update/delete, show author dialogs, create CF by model type (troubleshoot, spec, driver-download), audit trail, publish.',
     '["nw3s","aem","workflow"]', 'career_seed', '{"project_id":"a0000004-0001-4001-8001-000000000004"}'::jsonb, 'work', 'active'),
    ('a0000005-0001-4001-8001-000000000003'::uuid, admin_id, 'work_feature', 'VNA: Algolia Global Search Index Pipeline',
     'On page publish, workflow aggregates CF + FAQ + reusable component data, indexes to Algolia with reusable search design pattern.',
     '["vna","algolia","search"]', 'career_seed', '{"project_id":"a0000004-0001-4001-8001-000000000003"}'::jsonb, 'work', 'active'),
    ('a0000005-0001-4001-8001-000000000004'::uuid, admin_id, 'work_feature', 'Tini Coworking: IoT Device Integration',
     'Smart door, AC, camera, printer, RFID parking card APIs unified in NestJS backend.',
     '["tini","iot","integration"]', 'career_seed', '{"project_id":"a0000004-0001-4001-8001-000000000005"}'::jsonb, 'work', 'active')
    ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, content = EXCLUDED.content, updated_at = NOW();

    -- Design documents
    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status) VALUES
    ('a0000006-0001-4001-8001-000000000001'::uuid, admin_id, 'work_design_doc', 'NW3S — Current System Architecture',
     'FTP folder → NW3S instance (Data Sync Job hourly, Web Services/APIs, Data Publication, Logging, ES Indexing) → INET DB (DOC/LOG/EVENT) + Elasticsearch. Consumers: CUSA/CLA/CCI.',
     '["nw3s","architecture","documentum"]', 'career_seed',
     '{"project_id":"a0000004-0001-4001-8001-000000000004","image":"/work/design/nw3s-current-architecture.png","doc_type":"architecture"}'::jsonb,
     'work', 'active'),
    ('a0000006-0001-4001-8001-000000000002'::uuid, admin_id, 'work_design_doc', 'NW3S — Target AEM Migration Architecture',
     'Migrate Documentum → AEM Content Fragments. New modules: Web Services, Data Sync, Data Purification, ES Indexing. AEM stores CF + Workflows + LOG.',
     '["nw3s","aem","migration"]', 'career_seed',
     '{"project_id":"a0000004-0001-4001-8001-000000000004","image":"/work/design/nw3s-new-architecture.png","doc_type":"architecture"}'::jsonb,
     'work', 'active'),
    ('a0000006-0001-4001-8001-000000000003'::uuid, admin_id, 'work_design_doc', 'NW3S — Module Breakdown',
     'Modules: NW3S-API, ES Indexing, Batch Content Downloader, Batch Content Importer, Batch Event Logger. Repos on Canon SCM.',
     '["nw3s","modules"]', 'career_seed',
     '{"project_id":"a0000004-0001-4001-8001-000000000004","image":"/work/design/nw3s-modules.png","doc_type":"modules"}'::jsonb,
     'work', 'active'),
    ('a0000006-0001-4001-8001-000000000004'::uuid, admin_id, 'work_design_doc', 'VNA — Cloud Integration Architecture',
     'Adobe WebApp → WAF → Load Balancer → Integration Services (PROD/UAT/DEV) → Viettel Cloudrity → VNA backend. Third parties: Amadeus, Gimasys. Satellite: CLM, LotusAward, SSRM, Payment.',
     '["vna","architecture","cloud"]', 'career_seed',
     '{"project_id":"a0000004-0001-4001-8001-000000000003","image":"/work/design/vna-architecture.png","doc_type":"architecture"}'::jsonb,
     'work', 'active'),
    ('a0000006-0001-4001-8001-000000000005'::uuid, admin_id, 'work_design_doc', 'Destu — AEM to +CAS Content Sync Flow',
     'Author publish → Replication trigger → Custom workflow → Content Extractor (JSON) → POST /api/content/sync (JWT) → +CAS microservices → PostgreSQL/MongoDB → 200 OK.',
     '["destu","aem","sync"]', 'career_seed',
     '{"project_id":"a0000004-0001-4001-8001-000000000002","image":"/work/design/destu-aem-sync.png","doc_type":"sequence"}'::jsonb,
     'work', 'active')
    ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, content = EXCLUDED.content,
        metadata = EXCLUDED.metadata, updated_at = NOW();

    -- Technologies
    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status) VALUES
    ('a0000007-0001-4001-8001-000000000001'::uuid, admin_id, 'work_technology', 'Adobe Experience Manager (AEM)',
     'Components, templates, workflows, Content Fragments, HTL, Sling Models, AEM Cloud.',
     '["aem","cms"]', 'career_seed', '{"category":"platform","level":"advanced","years":2}'::jsonb, 'work', 'active'),
    ('a0000007-0001-4001-8001-000000000002'::uuid, admin_id, 'work_technology', 'Spring Boot',
     'REST APIs, batch jobs, Thymeleaf, migration 2→3, Java 7→11, unit testing.',
     '["java","spring-boot"]', 'career_seed', '{"category":"backend","level":"advanced","years":2}'::jsonb, 'work', 'active'),
    ('a0000007-0001-4001-8001-000000000003'::uuid, admin_id, 'work_technology', 'NestJS',
     'API design, MongoDB, Docker deployment, IoT integrations at TINI.',
     '["nestjs","nodejs"]', 'career_seed', '{"category":"backend","level":"advanced","years":2}'::jsonb, 'work', 'active'),
    ('a0000007-0001-4001-8001-000000000004'::uuid, admin_id, 'work_technology', 'Google Cloud Platform',
     'Cloud Run, scheduled jobs, enterprise deployment for NW3S pipeline.',
     '["gcp","cloud-run"]', 'career_seed', '{"category":"cloud","level":"intermediate"}'::jsonb, 'work', 'active'),
    ('a0000007-0001-4001-8001-000000000005'::uuid, admin_id, 'work_technology', 'Algolia Search',
     'Global search indexing pipeline on AEM publish for Vietnam Airlines.',
     '["algolia","search"]', 'career_seed', '{"category":"search","level":"advanced"}'::jsonb, 'work', 'active'),
    ('a0000007-0001-4001-8001-000000000006'::uuid, admin_id, 'work_technology', 'Elasticsearch',
     'NW3S troubleshoot content indexing and SEO optimization.',
     '["elasticsearch","search"]', 'career_seed', '{"category":"search","level":"intermediate"}'::jsonb, 'work', 'active'),
    ('a0000007-0001-4001-8001-000000000007'::uuid, admin_id, 'work_technology', 'PostgreSQL',
     'Migrated NW3S from Oracle; primary DB for enterprise workflows.',
     '["postgresql","database"]', 'career_seed', '{"category":"database","level":"advanced"}'::jsonb, 'work', 'active'),
    ('a0000007-0001-4001-8001-000000000008'::uuid, admin_id, 'work_technology', 'MongoDB',
     'Tini Trade and Tini Coworking document store.',
     '["mongodb","database"]', 'career_seed', '{"category":"database","level":"advanced"}'::jsonb, 'work', 'active')
    ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, content = EXCLUDED.content, updated_at = NOW();

    -- Decisions & lessons
    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status) VALUES
    ('a0000008-0001-4001-8001-000000000001'::uuid, admin_id, 'work_decision', 'NW3S: XSL-based Action Detection',
     'Use XSL verify templates to detect create/update/delete actions before AEM workflow branching — reduces manual author errors.',
     '["nw3s","xsl","workflow"]', 'career_seed',
     '{"date":"2025-06-01","status":"implemented","project_id":"a0000004-0001-4001-8001-000000000004"}'::jsonb, 'work', 'active'),
    ('a0000008-0001-4001-8001-000000000002'::uuid, admin_id, 'work_decision', 'VNA: Reusable Algolia Index Pattern',
     'Design pattern so each team''s components contribute searchable fields without duplicating index logic per page type.',
     '["vna","algolia","pattern"]', 'career_seed',
     '{"date":"2025-11-01","status":"implemented","project_id":"a0000004-0001-4001-8001-000000000003"}'::jsonb, 'work', 'active'),
    ('a0000008-0001-4001-8001-000000000003'::uuid, admin_id, 'work_lesson', 'Stack transition: NestJS → Java/AEM',
     'Moving from Node backend lead to enterprise AEM required leaning on workflow design, content models, and Java ecosystem patterns rather than API-only thinking.',
     '["career","aem","transition"]', 'career_seed',
     '{"project_id":"a0000004-0001-4001-8001-000000000004"}'::jsonb, 'work', 'active'),
    ('a0000008-0001-4001-8001-000000000004'::uuid, admin_id, 'work_lesson', 'IoT integrations need unified device abstraction',
     'At Tini Coworking, wrapping door/AC/camera/printer vendors behind one NestJS service layer simplified ops and reduced coupling.',
     '["tini","iot","architecture"]', 'career_seed',
     '{"project_id":"a0000004-0001-4001-8001-000000000005"}'::jsonb, 'work', 'active')
    ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, content = EXCLUDED.content, updated_at = NOW();

    -- Relationships
    INSERT INTO relationships (user_id, source_entity_id, target_entity_id, relation_type) VALUES
    -- roles → employers
    (admin_id, 'a0000003-0001-4001-8001-000000000001'::uuid, 'a0000002-0001-4001-8001-000000000001'::uuid, 'employed_at'),
    (admin_id, 'a0000003-0001-4001-8001-000000000002'::uuid, 'a0000002-0001-4001-8001-000000000002'::uuid, 'employed_at'),
    (admin_id, 'a0000003-0001-4001-8001-000000000003'::uuid, 'a0000002-0001-4001-8001-000000000002'::uuid, 'employed_at'),
    (admin_id, 'a0000003-0001-4001-8001-000000000004'::uuid, 'a0000002-0001-4001-8001-000000000003'::uuid, 'employed_at'),
    (admin_id, 'a0000003-0001-4001-8001-000000000005'::uuid, 'a0000002-0001-4001-8001-000000000004'::uuid, 'employed_at'),
    -- projects → roles/employers
    (admin_id, 'a0000004-0001-4001-8001-000000000001'::uuid, 'a0000003-0001-4001-8001-000000000001'::uuid, 'part_of'),
    (admin_id, 'a0000004-0001-4001-8001-000000000002'::uuid, 'a0000003-0001-4001-8001-000000000001'::uuid, 'part_of'),
    (admin_id, 'a0000004-0001-4001-8001-000000000003'::uuid, 'a0000003-0001-4001-8001-000000000001'::uuid, 'part_of'),
    (admin_id, 'a0000004-0001-4001-8001-000000000004'::uuid, 'a0000003-0001-4001-8001-000000000001'::uuid, 'part_of'),
    (admin_id, 'a0000004-0001-4001-8001-000000000005'::uuid, 'a0000003-0001-4001-8001-000000000002'::uuid, 'part_of'),
    (admin_id, 'a0000004-0001-4001-8001-000000000006'::uuid, 'a0000003-0001-4001-8001-000000000003'::uuid, 'part_of'),
    -- features → projects
    (admin_id, 'a0000005-0001-4001-8001-000000000001'::uuid, 'a0000004-0001-4001-8001-000000000004'::uuid, 'part_of'),
    (admin_id, 'a0000005-0001-4001-8001-000000000002'::uuid, 'a0000004-0001-4001-8001-000000000004'::uuid, 'part_of'),
    (admin_id, 'a0000005-0001-4001-8001-000000000003'::uuid, 'a0000004-0001-4001-8001-000000000003'::uuid, 'part_of'),
    (admin_id, 'a0000005-0001-4001-8001-000000000004'::uuid, 'a0000004-0001-4001-8001-000000000005'::uuid, 'part_of'),
    -- design docs → projects
    (admin_id, 'a0000006-0001-4001-8001-000000000001'::uuid, 'a0000004-0001-4001-8001-000000000004'::uuid, 'documents'),
    (admin_id, 'a0000006-0001-4001-8001-000000000002'::uuid, 'a0000004-0001-4001-8001-000000000004'::uuid, 'documents'),
    (admin_id, 'a0000006-0001-4001-8001-000000000003'::uuid, 'a0000004-0001-4001-8001-000000000004'::uuid, 'documents'),
    (admin_id, 'a0000006-0001-4001-8001-000000000004'::uuid, 'a0000004-0001-4001-8001-000000000003'::uuid, 'documents'),
    (admin_id, 'a0000006-0001-4001-8001-000000000005'::uuid, 'a0000004-0001-4001-8001-000000000002'::uuid, 'documents'),
    -- tech → projects
    (admin_id, 'a0000007-0001-4001-8001-000000000001'::uuid, 'a0000004-0001-4001-8001-000000000004'::uuid, 'used_in'),
    (admin_id, 'a0000007-0001-4001-8001-000000000002'::uuid, 'a0000004-0001-4001-8001-000000000004'::uuid, 'used_in'),
    (admin_id, 'a0000007-0001-4001-8001-000000000004'::uuid, 'a0000004-0001-4001-8001-000000000004'::uuid, 'used_in'),
    (admin_id, 'a0000007-0001-4001-8001-000000000006'::uuid, 'a0000004-0001-4001-8001-000000000004'::uuid, 'used_in'),
    (admin_id, 'a0000007-0001-4001-8001-000000000001'::uuid, 'a0000004-0001-4001-8001-000000000003'::uuid, 'used_in'),
    (admin_id, 'a0000007-0001-4001-8001-000000000005'::uuid, 'a0000004-0001-4001-8001-000000000003'::uuid, 'used_in'),
    (admin_id, 'a0000007-0001-4001-8001-000000000003'::uuid, 'a0000004-0001-4001-8001-000000000005'::uuid, 'used_in'),
    (admin_id, 'a0000007-0001-4001-8001-000000000008'::uuid, 'a0000004-0001-4001-8001-000000000005'::uuid, 'used_in'),
    -- decisions/lessons → projects
    (admin_id, 'a0000008-0001-4001-8001-000000000001'::uuid, 'a0000004-0001-4001-8001-000000000004'::uuid, 'related_to'),
    (admin_id, 'a0000008-0001-4001-8001-000000000002'::uuid, 'a0000004-0001-4001-8001-000000000003'::uuid, 'related_to'),
    (admin_id, 'a0000008-0001-4001-8001-000000000003'::uuid, 'a0000004-0001-4001-8001-000000000004'::uuid, 'related_to'),
    (admin_id, 'a0000008-0001-4001-8001-000000000004'::uuid, 'a0000004-0001-4001-8001-000000000005'::uuid, 'related_to')
    ON CONFLICT DO NOTHING;

    -- Queue embedding jobs for AI indexing
    INSERT INTO ai.embedding_jobs (user_id, source_table, entity_type, entity_id, status)
    SELECT admin_id, 'entities', e.type, e.id, 'pending'
    FROM entities e
    WHERE e.domain = 'work' AND e.source = 'career_seed'
      AND NOT EXISTS (
        SELECT 1 FROM ai.embedding_jobs j
        WHERE j.entity_id = e.id AND j.source_table = 'entities'
      );

    RAISE NOTICE 'Career work data seeded for user %', admin_id;
END $$;

-- Align searchable projection with WORK AI type for career indexing
CREATE OR REPLACE VIEW ai.searchable_content AS
SELECT
    e.id,
    e.user_id,
    CASE e.domain
        WHEN 'learning' THEN 'LEARNING'
        WHEN 'startup'  THEN 'STARTUP'
        WHEN 'goal'     THEN 'GOAL'
        WHEN 'journal'  THEN 'JOURNAL'
        WHEN 'work'     THEN 'WORK'
        ELSE 'TASK'
    END AS entity_type,
    'entities'::VARCHAR(50) AS source_table,
    e.title,
    e.content,
    e.tags,
    e.metadata,
    e.created_at,
    e.updated_at
FROM entities e
WHERE e.status = 'active'
UNION ALL
SELECT
    rp.id,
    rp.user_id,
    'BOOK'::VARCHAR(50) AS entity_type,
    'reading_progress'::VARCHAR(50) AS source_table,
    rp.story_title AS title,
    TRIM(BOTH FROM COALESCE(rp.chapter_title, '') || E'\n' || COALESCE(rp.current_url, '')) AS content,
    '[]'::JSONB AS tags,
    rp.metadata,
    rp.created_at,
    rp.updated_at
FROM reading_progress rp;
