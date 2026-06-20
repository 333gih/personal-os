-- Expand project design systems, TINI architecture, CV entries
-- REQUIRES: migrations/008_work_career_data.sql (run that first)
-- psql $DATABASE_URL -f migrations/009_work_design_cv.sql

DO $$
DECLARE
    admin_id UUID;
    career_owner_email TEXT := 'mphuc8671@gmail.com';
BEGIN
    SELECT id INTO admin_id FROM users
    WHERE lower(trim(email)) = lower(trim(career_owner_email))
    LIMIT 1;

    IF admin_id IS NULL THEN
        RAISE EXCEPTION 'Career owner % not found. Log in once with this email, then re-run migrations/010_work_career_all.sql', career_owner_email;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM entities
        WHERE id = 'a0000004-0001-4001-8001-000000000005'::uuid
    ) THEN
        RAISE EXCEPTION 'Missing career base data. Run first: psql $DATABASE_URL -f migrations/008_work_career_data.sql';
    END IF;
    -- Update Tini Coworking project with full design system
    UPDATE entities SET
        content = 'Coworking space platform: dual NestJS backends (Admin + User), Next.js Admin/User web, mobile app for members. Listing service maps campus → block → floor → room as NFT collections on blockchain for buy/sell. RabbitMQ handles async IoT (door unlock, AC, camera, printer paper orders, RFID parking). Backend lead: Docker on Ubuntu VPS, MongoDB.',
        tags = '["tini","coworking","nestjs","iot","nft","rabbitmq","blockchain"]'::jsonb,
        metadata = metadata || '{
            "design_images":["/work/design/tini-coworking-architecture.svg"],
            "architecture_layers":[
                {"layer":"Clients","nodes":["Next.js Admin","Next.js User","Mobile App","IoT Devices"]},
                {"layer":"API","nodes":["NestJS Admin API","NestJS User API"]},
                {"layer":"Services","nodes":["Listing Service (block/floor/room → NFT)","Booking","IoT Gateway","Payment"]},
                {"layer":"Async","nodes":["RabbitMQ workers"]},
                {"layer":"Data","nodes":["MongoDB","Blockchain NFT","Third-party IoT APIs"]}
            ],
            "stack":["NestJS","React","Next.js","MongoDB","RabbitMQ","Docker","Blockchain","Mobile"]
        }'::jsonb,
        updated_at = NOW()
    WHERE id = 'a0000004-0001-4001-8001-000000000005'::uuid;

    -- Update Tini Trade project
    UPDATE entities SET
        content = 'Trading platform at TINI: dual NestJS backends (Admin + User), Next.js Admin/User frontends, mobile app for traders. Features: market listing, orders, portfolio. RabbitMQ for async settlement, alerts, and webhook fan-out without blocking HTTP handlers.',
        tags = '["tini","trade","nestjs","mongodb","rabbitmq","mobile"]'::jsonb,
        metadata = metadata || '{
            "design_images":["/work/design/tini-trade-architecture.svg"],
            "architecture_layers":[
                {"layer":"Clients","nodes":["Next.js Admin","Next.js User","Mobile App"]},
                {"layer":"API","nodes":["NestJS Admin API","NestJS User API"]},
                {"layer":"Services","nodes":["Trading","Orders","Portfolio","Auth","Reporting"]},
                {"layer":"Async","nodes":["RabbitMQ"]},
                {"layer":"Data","nodes":["MongoDB","Redis","External market APIs"]}
            ],
            "stack":["NestJS","React","Next.js","MongoDB","RabbitMQ","Docker","Mobile"]
        }'::jsonb,
        updated_at = NOW()
    WHERE id = 'a0000004-0001-4001-8001-000000000006'::uuid;

    -- Tech Saas flow builder design system
    UPDATE entities SET
        metadata = metadata || '{
            "design_images":["/work/design/tech-saas-flow-builder.svg"],
            "architecture_layers":[
                {"layer":"Client","nodes":["Next.js + React Flow canvas"]},
                {"layer":"API","nodes":["Node.js REST API"]},
                {"layer":"Storage","nodes":["PostgreSQL / MongoDB"]}
            ]
        }'::jsonb,
        updated_at = NOW()
    WHERE id = 'a0000004-0001-4001-8001-000000000007'::uuid;

    -- FPT projects: structured architecture_layers + reference diagrams
    UPDATE entities SET
        metadata = metadata || '{
            "has_design_system": true,
            "design_images": ["/work/design/destu-aem-sync.png"],
            "architecture_layers": [
                {"layer": "AEM Author", "nodes": ["Publish", "Replication", "Custom Workflow", "Content Extractor (JSON)"]},
                {"layer": "Integration", "nodes": ["JWT Auth", "POST /api/content/sync", "Sling Models"]},
                {"layer": "+CAS Platform", "nodes": ["Microservices", "Content API", "Probo"]},
                {"layer": "Persistence", "nodes": ["PostgreSQL", "MongoDB"]}
            ]
        }'::jsonb,
        updated_at = NOW()
    WHERE id = 'a0000004-0001-4001-8001-000000000002'::uuid;

    UPDATE entities SET
        metadata = metadata || '{
            "has_design_system": true,
            "design_images": ["/work/design/vna-architecture.png"],
            "architecture_layers": [
                {"layer": "Presentation", "nodes": ["AEM WebApp", "HTL Components", "Content Fragments", "FAQ modules"]},
                {"layer": "Edge", "nodes": ["WAF", "Load Balancer", "Integration Services (DEV/UAT/PROD)"]},
                {"layer": "Cloud", "nodes": ["Viettel Cloudrity", "VNA Backend APIs"]},
                {"layer": "Search", "nodes": ["Publish Workflow", "Algolia Global Index", "Reusable index pattern"]},
                {"layer": "Third Party", "nodes": ["Amadeus", "Gimasys", "CLM", "LotusAward", "Payment"]}
            ]
        }'::jsonb,
        updated_at = NOW()
    WHERE id = 'a0000004-0001-4001-8001-000000000003'::uuid;

    UPDATE entities SET
        metadata = metadata || '{
            "has_design_system": true,
            "design_images": [
                "/work/design/nw3s-new-architecture.png",
                "/work/design/nw3s-current-architecture.png",
                "/work/design/nw3s-modules.png"
            ],
            "architecture_layers": [
                {"layer": "Ingest", "nodes": ["FTP/SFTP", "GCP Cloud Run", "Scheduled Jobs", "ZIP Batch Download"]},
                {"layer": "Processing", "nodes": ["Spring Boot 3", "XML Parser", "XSL Verify", "Create/Update/Delete detection"]},
                {"layer": "AEM", "nodes": ["Custom Workflows", "Content Fragments", "Author Dialogs", "Publish"]},
                {"layer": "Search & Portal", "nodes": ["Elasticsearch", "GraphQL API", "Thymeleaf Portal"]},
                {"layer": "Modules", "nodes": ["NW3S-API", "ES Indexing", "Batch Importer", "Event Logger"]}
            ]
        }'::jsonb,
        updated_at = NOW()
    WHERE id = 'a0000004-0001-4001-8001-000000000004'::uuid;

    -- FPT projects: ensure design_system flag (legacy rows)
    UPDATE entities SET metadata = metadata || '{"has_design_system":true}'::jsonb, updated_at = NOW()
    WHERE id IN (
        'a0000004-0001-4001-8001-000000000001'::uuid,
        'a0000004-0001-4001-8001-000000000002'::uuid,
        'a0000004-0001-4001-8001-000000000003'::uuid,
        'a0000004-0001-4001-8001-000000000004'::uuid
    );

    -- New design docs for TINI + Tech Saas
    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status) VALUES
    ('a0000006-0001-4001-8001-000000000006'::uuid, admin_id, 'work_design_doc', 'Tini Coworking — Full Stack Architecture',
     'Admin/User NestJS APIs, Next.js admin+user web, mobile app. Listing service: campus blocks/floors/rooms → NFT mint & marketplace on blockchain. RabbitMQ for door, printer, booking, parking RFID. MongoDB + IoT vendors.',
     '["tini","coworking","architecture","nft"]', 'career_seed',
     '{"project_id":"a0000004-0001-4001-8001-000000000005","image":"/work/design/tini-coworking-architecture.svg","doc_type":"architecture","has_design_system":true}'::jsonb,
     'work', 'active'),
    ('a0000006-0001-4001-8001-000000000007'::uuid, admin_id, 'work_design_doc', 'Tini Trade — Full Stack Architecture',
     'Admin/User NestJS APIs, Next.js admin+user, mobile app. Trading core + RabbitMQ async for orders and notifications.',
     '["tini","trade","architecture"]', 'career_seed',
     '{"project_id":"a0000004-0001-4001-8001-000000000006","image":"/work/design/tini-trade-architecture.svg","doc_type":"architecture","has_design_system":true}'::jsonb,
     'work', 'active'),
    ('a0000006-0001-4001-8001-000000000008'::uuid, admin_id, 'work_design_doc', 'Tech Saas — Flow Diagram Builder',
     'Next.js drag-drop flow editor (React Flow style), Node API persistence, export/share diagrams.',
     '["nextjs","flow","diagram"]', 'career_seed',
     '{"project_id":"a0000004-0001-4001-8001-000000000007","image":"/work/design/tech-saas-flow-builder.svg","doc_type":"architecture","has_design_system":true}'::jsonb,
     'work', 'active')
    ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, content = EXCLUDED.content,
        metadata = EXCLUDED.metadata, updated_at = NOW();

    -- New features
    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status) VALUES
    ('a0000005-0001-4001-8001-000000000005'::uuid, admin_id, 'work_feature', 'Tini Coworking: NFT Room Listing Service',
     'Service listing blocks/floors/rooms per campus zone; mint as NFT collections; marketplace buy/sell on blockchain.',
     '["tini","nft","blockchain"]', 'career_seed', '{"project_id":"a0000004-0001-4001-8001-000000000005"}'::jsonb, 'work', 'active'),
    ('a0000005-0001-4001-8001-000000000006'::uuid, admin_id, 'work_feature', 'Tini Coworking: RabbitMQ Async IoT',
     'Non-blocking door unlock, printer orders, meeting room booking, parking RFID via message queues.',
     '["tini","rabbitmq","iot"]', 'career_seed', '{"project_id":"a0000004-0001-4001-8001-000000000005"}'::jsonb, 'work', 'active'),
    ('a0000005-0001-4001-8001-000000000007'::uuid, admin_id, 'work_feature', 'Tini Trade: Dual Backend + Mobile',
     'Separate Admin and User NestJS services; Next.js admin/user FE; React Native / mobile app for end users.',
     '["tini","trade","mobile"]', 'career_seed', '{"project_id":"a0000004-0001-4001-8001-000000000006"}'::jsonb, 'work', 'active'),
    ('a0000005-0001-4001-8001-000000000008'::uuid, admin_id, 'work_feature', 'Tini Trade: RabbitMQ Async Pipeline',
     'Order settlement, alerts, webhooks processed async so API responses are not blocked.',
     '["tini","rabbitmq","trade"]', 'career_seed', '{"project_id":"a0000004-0001-4001-8001-000000000006"}'::jsonb, 'work', 'active')
    ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, content = EXCLUDED.content, updated_at = NOW();

    -- Technologies: RabbitMQ, Blockchain
    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status) VALUES
    ('a0000007-0001-4001-8001-000000000009'::uuid, admin_id, 'work_technology', 'RabbitMQ',
     'Async task processing at TINI — IoT commands, trade settlement, notifications without blocking APIs.',
     '["rabbitmq","messaging"]', 'career_seed', '{"category":"messaging","level":"advanced"}'::jsonb, 'work', 'active'),
    ('a0000007-0001-4001-8001-000000000010'::uuid, admin_id, 'work_technology', 'Blockchain / NFT',
     'Room listing as NFT collections for Tini Coworking marketplace.',
     '["blockchain","nft"]', 'career_seed', '{"category":"web3","level":"intermediate"}'::jsonb, 'work', 'active')
    ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, content = EXCLUDED.content, updated_at = NOW();

    -- CV entries: in CV (verified) + should add (recommended)
    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status) VALUES
    -- In CV
    ('a0000009-0001-4001-8001-000000000001'::uuid, admin_id, 'work_cv_entry', 'CV: FPT — AEM & Spring Boot enterprise delivery',
     'Develop, migrate Spring Boot 2→3, Java 7→11. AEM components, workflows, Content Fragments. REST, GraphQL, CI/CD, Docker, GCP.',
     '["cv","fpt","aem"]', 'career_seed',
     '{"cv_section":"experience","cv_status":"in_cv","company":"FPT Software","period":"2025–Present"}'::jsonb, 'work', 'active'),
    ('a0000009-0001-4001-8001-000000000002'::uuid, admin_id, 'work_cv_entry', 'CV: Canon NW3S — migration & integration',
     'Spring Boot + AEM + PostgreSQL + Elasticsearch. FTP pipeline, XSL action detection, unit tests >50%.',
     '["cv","nw3s","canon"]', 'career_seed',
     '{"cv_section":"projects","cv_status":"in_cv","project_id":"a0000004-0001-4001-8001-000000000004"}'::jsonb, 'work', 'active'),
    ('a0000009-0001-4001-8001-000000000003'::uuid, admin_id, 'work_cv_entry', 'CV: Vietnam Airlines — Algolia global search',
     'AEM components, publish workflow → Algolia index. Cross-team reusable search pattern.',
     '["cv","vna","algolia"]', 'career_seed',
     '{"cv_section":"projects","cv_status":"in_cv","project_id":"a0000004-0001-4001-8001-000000000003"}'::jsonb, 'work', 'active'),
    ('a0000009-0001-4001-8001-000000000004'::uuid, admin_id, 'work_cv_entry', 'CV: Destu Chugai — AEM Cloud migration',
     'AEM 6.5 → Cloud, components, workflows, Japanese client collaboration.',
     '["cv","destu","aem-cloud"]', 'career_seed',
     '{"cv_section":"projects","cv_status":"in_cv","project_id":"a0000004-0001-4001-8001-000000000002"}'::jsonb, 'work', 'active'),
    ('a0000009-0001-4001-8001-000000000005'::uuid, admin_id, 'work_cv_entry', 'CV: TINI — Backend Lead',
     'Led backend, NestJS APIs, CI/CD, IoT integrations (doors, AC, printers), mentored juniors.',
     '["cv","tini","backend-lead"]', 'career_seed',
     '{"cv_section":"experience","cv_status":"in_cv","company":"TINI GROUP","period":"2024–2025"}'::jsonb, 'work', 'active'),
    ('a0000009-0001-4001-8001-000000000006'::uuid, admin_id, 'work_cv_entry', 'CV: Tech Saas — Full-stack developer',
     'Full-stack apps, Ubuntu/AWS deploy, technical documentation.',
     '["cv","tech-saas"]', 'career_seed',
     '{"cv_section":"experience","cv_status":"in_cv","company":"Tech Saas Cloud Innovations"}'::jsonb, 'work', 'active'),
    -- Should add to CV (truthful, not yet on PDF)
    ('a0000009-0001-4001-8001-000000000010'::uuid, admin_id, 'work_cv_entry', 'Add to CV: Tini Coworking NFT + dual-stack architecture',
     'Highlight: Backend lead for admin/user APIs, mobile app, NFT room listing, RabbitMQ IoT, blockchain marketplace.',
     '["cv","recommended","tini"]', 'career_seed',
     '{"cv_section":"projects","cv_status":"recommended_add","project_id":"a0000004-0001-4001-8001-000000000005","priority":"high"}'::jsonb, 'work', 'active'),
    ('a0000009-0001-4001-8001-000000000011'::uuid, admin_id, 'work_cv_entry', 'Add to CV: Tini Trade dual backend + RabbitMQ',
     'Highlight: Separate admin/user NestJS services, mobile trading app, async order pipeline via RabbitMQ.',
     '["cv","recommended","tini"]', 'career_seed',
     '{"cv_section":"projects","cv_status":"recommended_add","project_id":"a0000004-0001-4001-8001-000000000006","priority":"high"}'::jsonb, 'work', 'active'),
    ('a0000009-0001-4001-8001-000000000012'::uuid, admin_id, 'work_cv_entry', 'Add to CV: NestJS → Java/AEM career transition',
     'Honest narrative: backend lead on Node stack, self-driven transition to enterprise AEM/Spring Boot at FPT.',
     '["cv","recommended","career"]', 'career_seed',
     '{"cv_section":"summary","cv_status":"recommended_add","priority":"medium"}'::jsonb, 'work', 'active'),
    ('a0000009-0001-4001-8001-000000000013'::uuid, admin_id, 'work_cv_entry', 'Add to CV: OpenRouter/AI integration (Personal OS)',
     'Built personal knowledge OS with OpenRouter DeepSeek, pgvector semantic search, career graph — shows AI tooling fluency.',
     '["cv","recommended","ai"]', 'career_seed',
     '{"cv_section":"skills","cv_status":"recommended_add","priority":"medium"}'::jsonb, 'work', 'active'),
    ('a0000009-0001-4001-8001-000000000014'::uuid, admin_id, 'work_cv_entry', 'Add to CV: NW3S system design ownership',
     'End-to-end: FTP→XML→XSL→AEM workflow→Content Fragment→ES SEO. Include architecture diagrams as portfolio.',
     '["cv","recommended","nw3s"]', 'career_seed',
     '{"cv_section":"projects","cv_status":"recommended_add","project_id":"a0000004-0001-4001-8001-000000000004","priority":"high"}'::jsonb, 'work', 'active')
    ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, content = EXCLUDED.content,
        metadata = EXCLUDED.metadata, updated_at = NOW();

    -- Relationships for new entities (skip rows when FK targets missing)
    INSERT INTO relationships (user_id, source_entity_id, target_entity_id, relation_type)
    SELECT admin_id, v.source_id, v.target_id, v.relation_type
    FROM (VALUES
        ('a0000006-0001-4001-8001-000000000006'::uuid, 'a0000004-0001-4001-8001-000000000005'::uuid, 'documents'),
        ('a0000006-0001-4001-8001-000000000007'::uuid, 'a0000004-0001-4001-8001-000000000006'::uuid, 'documents'),
        ('a0000006-0001-4001-8001-000000000008'::uuid, 'a0000004-0001-4001-8001-000000000007'::uuid, 'documents'),
        ('a0000005-0001-4001-8001-000000000005'::uuid, 'a0000004-0001-4001-8001-000000000005'::uuid, 'part_of'),
        ('a0000005-0001-4001-8001-000000000006'::uuid, 'a0000004-0001-4001-8001-000000000005'::uuid, 'part_of'),
        ('a0000005-0001-4001-8001-000000000007'::uuid, 'a0000004-0001-4001-8001-000000000006'::uuid, 'part_of'),
        ('a0000005-0001-4001-8001-000000000008'::uuid, 'a0000004-0001-4001-8001-000000000006'::uuid, 'part_of'),
        ('a0000007-0001-4001-8001-000000000009'::uuid, 'a0000004-0001-4001-8001-000000000005'::uuid, 'used_in'),
        ('a0000007-0001-4001-8001-000000000009'::uuid, 'a0000004-0001-4001-8001-000000000006'::uuid, 'used_in'),
        ('a0000007-0001-4001-8001-000000000010'::uuid, 'a0000004-0001-4001-8001-000000000005'::uuid, 'used_in'),
        ('a0000009-0001-4001-8001-000000000010'::uuid, 'a0000004-0001-4001-8001-000000000005'::uuid, 'related_to'),
        ('a0000009-0001-4001-8001-000000000011'::uuid, 'a0000004-0001-4001-8001-000000000006'::uuid, 'related_to'),
        ('a0000009-0001-4001-8001-000000000014'::uuid, 'a0000004-0001-4001-8001-000000000004'::uuid, 'related_to')
    ) AS v(source_id, target_id, relation_type)
    WHERE EXISTS (SELECT 1 FROM entities e WHERE e.id = v.source_id)
      AND EXISTS (SELECT 1 FROM entities e WHERE e.id = v.target_id)
    ON CONFLICT DO NOTHING;
    INSERT INTO ai.embedding_jobs (user_id, source_table, entity_type, entity_id, status)
    SELECT admin_id, 'entities', e.type, e.id, 'pending'
    FROM entities e
    WHERE e.source = 'career_seed' AND e.updated_at > NOW() - INTERVAL '1 minute'
      AND NOT EXISTS (
        SELECT 1 FROM ai.embedding_jobs j WHERE j.entity_id = e.id AND j.source_table = 'entities'
      );

    RAISE NOTICE 'Design systems and CV entries updated';
END $$;
