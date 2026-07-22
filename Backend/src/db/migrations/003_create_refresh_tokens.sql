CREATE TABLE IF NOT EXISTS refresh_tokens (
  token_id    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID        NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  token_hash  TEXT        NOT NULL UNIQUE,
  device_type VARCHAR(50),
  last_used   TIMESTAMP   NOT NULL DEFAULT NOW(),
  expires_at  TIMESTAMP   NOT NULL,
  is_revoked  BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user    ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_revoked ON refresh_tokens(is_revoked);
