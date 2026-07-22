CREATE TABLE IF NOT EXISTS payouts (
  payout_id     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id      UUID         NOT NULL REFERENCES equb_groups(group_id) ON DELETE CASCADE,
  member_id     UUID         NOT NULL REFERENCES group_members(member_id) ON DELETE CASCADE,
  payout_amount DECIMAL(12,2) NOT NULL,
  payout_date   TIMESTAMP    NOT NULL DEFAULT NOW(),
  cycle_number  INT          NOT NULL,
  status        VARCHAR(20)  NOT NULL DEFAULT 'pending', -- pending | completed | rejected
  created_at    TIMESTAMP    NOT NULL DEFAULT NOW(),
  UNIQUE(group_id, cycle_number)  -- enforces one payout per cycle per group
);

CREATE INDEX IF NOT EXISTS idx_payouts_group  ON payouts(group_id);
CREATE INDEX IF NOT EXISTS idx_payouts_member ON payouts(member_id);
CREATE INDEX IF NOT EXISTS idx_payouts_status ON payouts(status);

ALTER TABLE payouts ADD CONSTRAINT chk_payouts_status
  CHECK (status IN ('pending', 'completed', 'rejected'));

ALTER TABLE payouts ADD CONSTRAINT chk_payouts_amount_positive
  CHECK (payout_amount > 0);
