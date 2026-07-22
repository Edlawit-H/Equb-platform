CREATE TABLE IF NOT EXISTS audit_logs (
  log_id      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID        REFERENCES users(user_id) ON DELETE SET NULL,
  action      TEXT        NOT NULL,
  entity_name VARCHAR(50),
  entity_id   UUID,
  timestamp   TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_user      ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action    ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp ON audit_logs(timestamp);

-- Make audit_logs append-only: revoke UPDATE and DELETE from application role
-- Run this as DB superuser after migration:
-- REVOKE UPDATE, DELETE ON audit_logs FROM equb_app_user;
