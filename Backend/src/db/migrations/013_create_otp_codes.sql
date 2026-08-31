CREATE TABLE IF NOT EXISTS otp_codes (
  otp_id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      UUID REFERENCES users(user_id) ON DELETE CASCADE,
  phone_number VARCHAR(20) NOT NULL,
  otp_code     VARCHAR(6)  NOT NULL,
  purpose      VARCHAR(30) NOT NULL CHECK (purpose IN ('registration', 'forgot_password', 'verification', 'password_change', 'phone_update', 'login')),
  verified     BOOLEAN     NOT NULL DEFAULT FALSE,
  expires_at   TIMESTAMP   NOT NULL,
  created_at   TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_otp_codes_phone   ON otp_codes(phone_number);
CREATE INDEX IF NOT EXISTS idx_otp_codes_purpose ON otp_codes(purpose);
CREATE INDEX IF NOT EXISTS idx_otp_codes_expires ON otp_codes(expires_at);
