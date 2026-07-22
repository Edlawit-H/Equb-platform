CREATE TABLE IF NOT EXISTS users (
  user_id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  full_name         VARCHAR(150) NOT NULL,
  phone_number      VARCHAR(20)  UNIQUE NOT NULL,
  email             VARCHAR(150),
  password_hash     TEXT         NOT NULL,
  profile_image     TEXT,
  role              VARCHAR(20)  NOT NULL DEFAULT 'member',       -- member | system_admin
  status            VARCHAR(30)  NOT NULL DEFAULT 'pending_verification', -- pending_verification | active | suspended
  wallet_balance    DECIMAL(12,2) NOT NULL DEFAULT 0.00,          -- initialized by DB default
  biometric_enabled BOOLEAN      NOT NULL DEFAULT FALSE,
  is_deleted        BOOLEAN      NOT NULL DEFAULT FALSE,
  created_at        TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_phone  ON users(phone_number);
CREATE INDEX IF NOT EXISTS idx_users_email  ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);

ALTER TABLE users ADD CONSTRAINT chk_users_role
  CHECK (role IN ('member', 'system_admin'));

ALTER TABLE users ADD CONSTRAINT chk_users_status
  CHECK (status IN ('pending_verification', 'active', 'suspended'));

ALTER TABLE users ADD CONSTRAINT chk_users_wallet_non_negative
  CHECK (wallet_balance >= 0.00);
