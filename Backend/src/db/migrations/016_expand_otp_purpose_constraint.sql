DO $$
DECLARE
    r RECORD;
BEGIN
    -- Drop all existing check constraints on the otp_codes purpose column dynamically
    FOR r IN (
        SELECT conname
        FROM pg_constraint
        WHERE conrelid = 'otp_codes'::regclass
          AND contype = 'c'
          AND pg_get_constraintdef(oid) LIKE '%purpose%'
    ) LOOP
        EXECUTE 'ALTER TABLE otp_codes DROP CONSTRAINT IF EXISTS ' || quote_ident(r.conname);
    END LOOP;
END $$;

-- Add updated comprehensive check constraint for all valid OTP purposes
ALTER TABLE otp_codes
ADD CONSTRAINT chk_otp_purpose
CHECK (purpose IN ('registration', 'forgot_password', 'verification', 'password_change', 'phone_update', 'login'));
