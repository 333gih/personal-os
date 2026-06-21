-- Fash startup ecosystem seed (from D:/Project/fash monorepo)
-- psql $DATABASE_URL -f migrations/019_fash_startup_seed.sql

DO $$
DECLARE
    admin_id UUID;
    owner_email TEXT := 'mphuc8671@gmail.com';
BEGIN
    SELECT id INTO admin_id FROM users
    WHERE lower(trim(email)) = lower(trim(owner_email))
    LIMIT 1;

    IF admin_id IS NULL THEN
        RAISE NOTICE 'Owner % not found — skip Fash startup seed', owner_email;
        RETURN;
    END IF;

    DELETE FROM entities
    WHERE user_id = admin_id AND domain = 'startup' AND source = 'fash_seed';

    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status) VALUES
    ('b000000b-0001-4001-8001-000000000001'::uuid, admin_id, 'startup_idea', 'Fash — Fashion Resale Marketplace',
     'Mobile-first C2C fashion marketplace (iOS, Android, web). Microservices: Kong gateway, auth, core listings/checkout, realtime WebSocket chat, Kafka notifications. Goal: trusted resale with personalized feed, sizing, and seasonal recommendations.',
     '["fash","marketplace","mvp"]'::jsonb, 'fash_seed',
     '{"stage": "growth", "priority": "high", "repo": "D:/Project/fash", "stack": ["Go", "Kong", "Kafka", "Redis", "PostgreSQL", "Swift", "Kotlin"]}'::jsonb,
     'startup', 'active'),

    ('b000000b-0001-4001-8001-000000000002'::uuid, admin_id, 'startup_business_model', 'Fash revenue model',
     'Commission on completed sales, promoted listings, optional seller subscriptions. Payment and checkout via core-service with intent tracking and feed attribution.',
     '["fash","revenue"]'::jsonb, 'fash_seed',
     '{"model": "marketplace_take_rate"}'::jsonb, 'startup', 'active'),

    ('b000000b-0001-4001-8001-000000000003'::uuid, admin_id, 'startup_feature', 'Personalized home feed & recommendations',
     'Hybrid ranking: engagement × taste profile. Home sections: for_you, style_picks, continue_browsing, similar_to_saved, seasonal_near_you, shopping_context. Sizing mode match_profile vs all.',
     '["fash","recommendations"]'::jsonb, 'fash_seed',
     '{"service": "core-service", "apis": ["/recommendations/home-sections", "/recommendations/explore-listings"]}'::jsonb,
     'startup', 'active'),

    ('b000000b-0001-4001-8001-000000000004'::uuid, admin_id, 'startup_feature', 'Realtime chat & presence',
     'WebSocket service for buyer-seller messaging and presence. Load-tested via fash-perf-platform socket scenarios.',
     '["fash","realtime"]'::jsonb, 'fash_seed',
     '{"service": "realtime-service", "path": "/ws"}'::jsonb, 'startup', 'active'),

    ('b000000b-0001-4001-8001-000000000005'::uuid, admin_id, 'startup_feature', 'Kong API Gateway (JWT, rate limit)',
     'Single ingress: JWT from fash-auth-service, Redis-backed rate limits, CORS, route to auth/core/payment/notification/realtime upstreams.',
     '["fash","infra"]'::jsonb, 'fash_seed',
     '{"service": "fash-api-gateway", "version": "Kong 3.7"}'::jsonb, 'startup', 'active'),

    ('b000000b-0001-4001-8001-000000000006'::uuid, admin_id, 'startup_competitor', 'Depop',
     'Global fashion resale app — benchmark for social discovery and mobile UX.',
     '["competitor"]'::jsonb, 'fash_seed', '{"url": "https://www.depop.com"}'::jsonb, 'startup', 'active'),

    ('b000000b-0001-4001-8001-000000000007'::uuid, admin_id, 'startup_competitor', 'Vinted',
     'EU-focused C2C fashion marketplace — benchmark for listing flow and trust.',
     '["competitor"]'::jsonb, 'fash_seed', '{"url": "https://www.vinted.com"}'::jsonb, 'startup', 'active'),

    ('b000000b-0001-4001-8001-000000000008'::uuid, admin_id, 'startup_kpi', 'Listing catalog scale',
     'Target: 20k+ seeded listings for recommendation tuning; perf gate via fash-perf-platform k6/Artillery.',
     '["fash","kpi"]'::jsonb, 'fash_seed',
     '{"metric": "active_listings", "target": "20000+"}'::jsonb, 'startup', 'active'),

    ('b000000b-0001-4001-8001-000000000009'::uuid, admin_id, 'startup_kpi', 'Gateway p99 latency',
     'Kong + core-service SLO under load — login-storm, checkout-flow, websocket-concurrent scenarios.',
     '["fash","kpi","perf"]'::jsonb, 'fash_seed',
     '{"metric": "p99_ms", "target": "<500 under baseline load"}'::jsonb, 'startup', 'active'),

    ('b000000b-0001-4001-8001-000000000010'::uuid, admin_id, 'startup_pain_point', 'Distributed perf at scale',
     'Need continuous load/chaos testing across Kong, Kafka, Redis Streams, and WebSocket fan-out before major releases.',
     '["fash","risk"]'::jsonb, 'fash_seed',
     '{"mitigation": "fash-perf-platform"}'::jsonb, 'startup', 'active');

    RAISE NOTICE 'Fash startup seed applied for %', owner_email;
END $$;
