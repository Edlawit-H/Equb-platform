CREATE TABLE IF NOT EXISTS device_tokens (
  token_id   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID        NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  fcm_token  TEXT        NOT NULL UNIQUE,
  platform   VARCHAR(10) NOT NULL,   -- android | ios
  created_at TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON device_tokens(user_id);

ALTER TABLE device_tokens ADD CONSTRAINT chk_device_platform
  CHECK (platform IN ('android', 'ios'));
