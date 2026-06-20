-- Idempotent patch: FPT project architecture_layers (runs on owner login)
DO $$
BEGIN
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
END $$;
