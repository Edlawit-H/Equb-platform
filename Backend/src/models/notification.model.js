/**
 * @typedef {Object} Notification
 * @property {string} notification_id
 * @property {string} user_id
 * @property {string} title
 * @property {string} message
 * @property {'payment_reminder'|'overdue_alert'|'payout_received'|'group_activity'|'group_completed'} type
 * @property {boolean} is_read
 * @property {Date} created_at
 */

/**
 * @typedef {Object} NotificationPreference
 * @property {string} pref_id
 * @property {string} user_id
 * @property {boolean} payment_reminders
 * @property {boolean} payout_alerts
 * @property {boolean} group_activity
 * @property {Date} updated_at
 */
