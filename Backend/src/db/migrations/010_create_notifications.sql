CREATE TABLE IF NOT EXISTS notifications (
  notification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID        NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  title           VARCHAR(150) NOT NULL,
  message         TEXT        NOT NULL,
  type            VARCHAR(30) NOT NULL,  -- payment_reminder | overdue_alert | payout_received | group_activity | group_completed
  is_read         BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user    ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read    ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at);

ALTER TABLE notifications ADD CONSTRAINT chk_notifications_type
  CHECK (type IN ('payment_reminder', 'overdue_alert', 'payout_received', 'group_activity', 'group_completed'));
