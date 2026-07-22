CREATE TABLE IF NOT EXISTS contributions (
  contribution_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  member_id       UUID         NOT NULL REFERENCES group_members(member_id) ON DELETE CASCADE,
  group_id        UUID         NOT NULL REFERENCES equb_groups(group_id) ON DELETE CASCADE,
  cycle_number    INT          NOT NULL,
  amount          DECIMAL(12,2) NOT NULL,
  due_date        DATE         NOT NULL,
  paid_date       TIMESTAMP,
  status          VARCHAR(20)  NOT NULL DEFAULT 'pending', -- pending | paid | overdue
  created_at      TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_contributions_member  ON contributions(member_id);
CREATE INDEX IF NOT EXISTS idx_contributions_group   ON contributions(group_id);
CREATE INDEX IF NOT EXISTS idx_contributions_cycle   ON contributions(group_id, cycle_number);
CREATE INDEX IF NOT EXISTS idx_contributions_status  ON contributions(status);
CREATE INDEX IF NOT EXISTS idx_contributions_due     ON contributions(due_date);

ALTER TABLE contributions ADD CONSTRAINT chk_contributions_status
  CHECK (status IN ('pending', 'paid', 'overdue'));

ALTER TABLE contributions ADD CONSTRAINT chk_contributions_amount_positive
  CHECK (amount > 0);
