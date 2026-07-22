CREATE TABLE IF NOT EXISTS notification_preferences (
  pref_id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id            UUID      NOT NULL UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
  payment_reminders  BOOLEAN   NOT NULL DEFAULT TRUE,
  payout_alerts      BOOLEAN   NOT NULL DEFAULT TRUE,
  group_activity     BOOLEAN   NOT NULL DEFAULT TRUE,
  updated_at         TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notification_prefs_user ON notification_preferences(user_id);
