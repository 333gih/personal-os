-- Structured architecture_layers for FPT projects (VNA, Canon NW3S, Destu).
-- TINI projects already have layers in 009; these had design_images only.
-- psql $DATABASE_URL -f migrations/013_fpt_architecture_layers.sql

DO $$
BEGIN
    -- Destu (Chugai) — AEM Cloud migration + +CAS sync
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

    -- Vietnam Airlines — AEM + Algolia + cloud integration
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

    -- Canon NW3S — Documentum → AEM migration pipeline
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

    -- Design docs: mirror layers for linked project diagrams
    UPDATE entities SET
        metadata = metadata || '{"has_design_system": true, "architecture_layers": [
            {"layer": "Legacy", "nodes": ["FTP folder", "NW3S Data Sync", "Web Services", "INET DB", "Elasticsearch"]},
            {"layer": "Consumers", "nodes": ["CUSA", "CLA", "CCI"]}
        ]}'::jsonb,
        updated_at = NOW()
    WHERE id = 'a0000006-0001-4001-8001-000000000001'::uuid;

    UPDATE entities SET
        metadata = metadata || '{"has_design_system": true, "architecture_layers": [
            {"layer": "Ingest", "nodes": ["FTP/SFTP", "GCP Cloud Run", "Batch Downloader"]},
            {"layer": "AEM Target", "nodes": ["Content Fragments", "Workflows", "Data Purification", "ES Indexing"]}
        ]}'::jsonb,
        updated_at = NOW()
    WHERE id = 'a0000006-0001-4001-8001-000000000002'::uuid;

    UPDATE entities SET
        metadata = metadata || '{"has_design_system": true, "architecture_layers": [
            {"layer": "Services", "nodes": ["NW3S-API", "ES Indexing", "Batch Content Downloader"]},
            {"layer": "Batch", "nodes": ["Batch Content Importer", "Batch Event Logger", "Canon SCM repos"]}
        ]}'::jsonb,
        updated_at = NOW()
    WHERE id = 'a0000006-0001-4001-8001-000000000003'::uuid;

    UPDATE entities SET
        metadata = metadata || '{"has_design_system": true, "architecture_layers": [
            {"layer": "Presentation", "nodes": ["Adobe WebApp", "AEM Components"]},
            {"layer": "Integration", "nodes": ["WAF", "Load Balancer", "Integration Services"]},
            {"layer": "Backend", "nodes": ["Viettel Cloudrity", "VNA APIs", "Amadeus", "Gimasys"]}
        ]}'::jsonb,
        updated_at = NOW()
    WHERE id = 'a0000006-0001-4001-8001-000000000004'::uuid;

    UPDATE entities SET
        metadata = metadata || '{"has_design_system": true, "architecture_layers": [
            {"layer": "AEM Author", "nodes": ["Publish", "Replication trigger", "Custom workflow"]},
            {"layer": "Sync", "nodes": ["Content Extractor", "JWT", "POST /api/content/sync"]},
            {"layer": "+CAS", "nodes": ["Microservices", "PostgreSQL", "MongoDB"]}
        ]}'::jsonb,
        updated_at = NOW()
    WHERE id = 'a0000006-0001-4001-8001-000000000005'::uuid;

    RAISE NOTICE 'FPT architecture_layers applied for Destu, VNA, Canon NW3S';
END $$;
