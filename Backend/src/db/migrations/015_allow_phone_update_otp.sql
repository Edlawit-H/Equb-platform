ALTER TABLE otp_codes DROP CONSTRAINT IF EXISTS chk_otp_purpose;

ALTER TABLE otp_codes ADD CONSTRAINT chk_otp_purpose
  CHECK (purpose IN ('registration', 'forgot_password', 'phone_update'));
