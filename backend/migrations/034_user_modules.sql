-- Per-user module enable/pin/config preferences
CREATE TABLE IF NOT EXISTS user_module_prefs (
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    module_id  VARCHAR(32) NOT NULL,
    enabled    BOOLEAN NOT NULL DEFAULT true,
    pin_order  INT,
    config     JSONB NOT NULL DEFAULT '{}',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, module_id)
);

CREATE INDEX IF NOT EXISTS idx_user_module_prefs_user ON user_module_prefs(user_id);

-- OAuth tokens for third-party integrations (calendar, etc.)
CREATE TABLE IF NOT EXISTS user_integration_tokens (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider      VARCHAR(32) NOT NULL,
    access_token  TEXT NOT NULL,
    refresh_token TEXT,
    token_type    VARCHAR(32) NOT NULL DEFAULT 'Bearer',
    expires_at    TIMESTAMPTZ,
    scopes        TEXT,
    metadata      JSONB NOT NULL DEFAULT '{}',
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, provider)
);

CREATE INDEX IF NOT EXISTS idx_user_integration_tokens_user ON user_integration_tokens(user_id);
