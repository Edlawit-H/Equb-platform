CREATE TABLE IF NOT EXISTS equb_groups (
  group_id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_name          VARCHAR(150) NOT NULL,
  description         TEXT,
  admin_id            UUID         NOT NULL REFERENCES users(user_id),
  invitation_code     CHAR(8)      NOT NULL UNIQUE,
  contribution_amount DECIMAL(12,2) NOT NULL,
  cycle_duration      INT          NOT NULL,             -- 7, 14, or 30 days
  max_members         INT          NOT NULL,             -- 2–50
  current_cycle       INT          NOT NULL DEFAULT 1,    -- incremented by payout service
  selection_mode      VARCHAR(20)  NOT NULL DEFAULT 'positional', -- positional | random
  start_date          DATE,
  end_date            DATE,
  status              VARCHAR(20)  NOT NULL DEFAULT 'pending', -- pending | ready | active | completed | cancelled
  is_deleted          BOOLEAN      NOT NULL DEFAULT FALSE,
  created_at          TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_equb_groups_admin        ON equb_groups(admin_id);
CREATE INDEX IF NOT EXISTS idx_equb_groups_invite_code  ON equb_groups(invitation_code);
CREATE INDEX IF NOT EXISTS idx_equb_groups_status       ON equb_groups(status);

ALTER TABLE equb_groups ADD CONSTRAINT chk_groups_cycle_duration
  CHECK (cycle_duration IN (7, 14, 30));

ALTER TABLE equb_groups ADD CONSTRAINT chk_groups_max_members
  CHECK (max_members >= 2 AND max_members <= 50);

ALTER TABLE equb_groups ADD CONSTRAINT chk_groups_status
  CHECK (status IN ('pending', 'ready', 'active', 'completed', 'cancelled'));

ALTER TABLE equb_groups ADD CONSTRAINT chk_groups_selection_mode
  CHECK (selection_mode IN ('positional', 'random'));

ALTER TABLE equb_groups ADD CONSTRAINT chk_groups_contribution_positive
  CHECK (contribution_amount > 0);
