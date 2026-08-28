-- 1. Loans Table
CREATE TABLE IF NOT EXISTS loans (
  loan_id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  member_id     UUID          NOT NULL REFERENCES group_members(member_id) ON DELETE CASCADE,
  group_id      UUID          NOT NULL REFERENCES equb_groups(group_id) ON DELETE CASCADE,
  amount        DECIMAL(12,2) NOT NULL CHECK (amount > 0),
  interest_rate DECIMAL(5,2)  NOT NULL DEFAULT 0.00 CHECK (interest_rate >= 0),
  request_date  TIMESTAMP     NOT NULL DEFAULT NOW(),
  approval_date TIMESTAMP,
  status        VARCHAR(20)   NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'paid')),
  created_at    TIMESTAMP     NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_loans_member ON loans(member_id);
CREATE INDEX IF NOT EXISTS idx_loans_group  ON loans(group_id);
CREATE INDEX IF NOT EXISTS idx_loans_status ON loans(status);

-- 2. Loan Repayments Table
CREATE TABLE IF NOT EXISTS loan_repayments (
  repayment_id      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  loan_id           UUID          NOT NULL REFERENCES loans(loan_id) ON DELETE CASCADE,
  amount            DECIMAL(12,2) NOT NULL CHECK (amount > 0),
  payment_date      TIMESTAMP     NOT NULL DEFAULT NOW(),
  remaining_balance DECIMAL(12,2) NOT NULL DEFAULT 0.00 CHECK (remaining_balance >= 0.00),
  created_at        TIMESTAMP     NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_loan_repayments_loan ON loan_repayments(loan_id);
