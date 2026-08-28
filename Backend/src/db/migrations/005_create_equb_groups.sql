CREATE TABLE IF NOT EXISTS equb_groups (
  group_id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_name          VARCHAR(150) NOT NULL,
  description         TEXT,
  admin_id            UUID         NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
  invitation_code     CHAR(8)      NOT NULL UNIQUE,
  contribution_amount DECIMAL(12,2) NOT NULL CHECK (contribution_amount > 0),
  cycle_duration      INT          NOT NULL CHECK (cycle_duration IN (1, 7, 14, 30)),
  max_members         INT          NOT NULL CHECK (max_members >= 2 AND max_members <= 100),
  current_cycle       INT          NOT NULL DEFAULT 1,
  total_cycles        INT,
  start_date          DATE,
  end_date            DATE,
  cycle_end_date      DATE,
  status              VARCHAR(20)  NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'ready', 'active', 'completed', 'cancelled')),
  is_deleted          BOOLEAN      NOT NULL DEFAULT FALSE,
  created_at          TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_equb_groups_admin        ON equb_groups(admin_id);
CREATE INDEX IF NOT EXISTS idx_equb_groups_invite_code  ON equb_groups(invitation_code);
CREATE INDEX IF NOT EXISTS idx_equb_groups_status       ON equb_groups(status);
