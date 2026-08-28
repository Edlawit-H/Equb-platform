CREATE TABLE IF NOT EXISTS users (
  user_id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  full_name         VARCHAR(150) NOT NULL,
  phone_number      VARCHAR(20)  UNIQUE NOT NULL,
  email             VARCHAR(150),
  password_hash     TEXT         NOT NULL,
  profile_image     TEXT,
  role              VARCHAR(20)  NOT NULL DEFAULT 'member' CHECK (role IN ('member', 'admin', 'system_admin')),
  status            VARCHAR(30)  NOT NULL DEFAULT 'active' CHECK (status IN ('pending_verification', 'active', 'inactive', 'suspended')),
  wallet_balance    DECIMAL(12,2) NOT NULL DEFAULT 0.00 CHECK (wallet_balance >= 0.00),
  biometric_enabled BOOLEAN      NOT NULL DEFAULT FALSE,
  is_deleted        BOOLEAN      NOT NULL DEFAULT FALSE,
  created_at        TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_phone  ON users(phone_number);
CREATE INDEX IF NOT EXISTS idx_users_email  ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
