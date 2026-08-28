CREATE TABLE IF NOT EXISTS group_members (
  member_id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID        NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  group_id          UUID        NOT NULL REFERENCES equb_groups(group_id) ON DELETE CASCADE,
  join_date         TIMESTAMP   NOT NULL DEFAULT NOW(),
  position_in_cycle INT         NOT NULL,
  role              VARCHAR(20) NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'co_admin', 'member')),
  status            VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'removed', 'left')),
  UNIQUE(user_id, group_id)
);

CREATE INDEX IF NOT EXISTS idx_group_members_user  ON group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_group_members_group ON group_members(group_id);
