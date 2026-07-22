export interface Notification {
  notification_id: string;
  user_id: string;
  title: string;
  message: string;
  type: 'payment_reminder' | 'overdue_alert' | 'payout_received' | 'group_activity' | 'group_completed';
  is_read: boolean;
  created_at: Date;
}

export interface NotificationPreference {
  pref_id: string;
  user_id: string;
  payment_reminders: boolean;
  payout_alerts: boolean;
  group_activity: boolean;
  updated_at: Date;
}
