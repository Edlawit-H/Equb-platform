CREATE TABLE IF NOT EXISTS transactions (
  transaction_id   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID         NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  group_id         UUID REFERENCES equb_groups(group_id) ON DELETE SET NULL,
  type             VARCHAR(30)  NOT NULL CHECK (type IN ('top_up', 'contribution', 'contribution_debit', 'payout', 'payout_credit', 'loan', 'repayment', 'adjustment')),
  amount           DECIMAL(12,2) NOT NULL,
  payment_method   VARCHAR(50)  DEFAULT 'digital_wallet',
  reference_number VARCHAR(100),
  status           VARCHAR(20)  NOT NULL DEFAULT 'completed',
  created_at       TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_transactions_user      ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_group     ON transactions(group_id);
CREATE INDEX IF NOT EXISTS idx_transactions_type      ON transactions(type);
CREATE INDEX IF NOT EXISTS idx_transactions_created   ON transactions(created_at);
