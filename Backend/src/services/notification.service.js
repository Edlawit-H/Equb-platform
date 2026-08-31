import pool from '../config/db.js';
import { AppError } from '../utils/AppError.js';


export const getUserNotifications = async (userId, options = {}) => {
  const { is_read, type, limit = 20, offset = 0 } = options;

  let query = 'SELECT * FROM notifications WHERE user_id = $1';
  const params = [userId];
  let paramIndex = 2;

  if (is_read !== undefined && is_read !== null && is_read !== '') {
    const readBool = is_read === true || is_read === 'true';
    query += ` AND is_read = $${paramIndex}`;
    params.push(readBool);
    paramIndex++;
  }

  if (type) {
    query += ` AND type = $${paramIndex}`;
    params.push(type);
    paramIndex++;
  }

  // Count unread
  const unreadRes = await pool.query(
    'SELECT COUNT(*) FROM notifications WHERE user_id = $1 AND is_read = FALSE',
    [userId]
  );
  const unreadCount = parseInt(unreadRes.rows[0].count, 10) || 0;

  // Count total for this filter
  const countQuery = query.replace('SELECT *', 'SELECT COUNT(*)');
  const totalRes = await pool.query(countQuery, params);
  const total = parseInt(totalRes.rows[0].count, 10) || 0;

  // Add ordering and pagination
  query += ` ORDER BY created_at DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
  params.push(Number(limit) || 20, Number(offset) || 0);

  const { rows } = await pool.query(query, params);

  return {
    total,
    unread_count: unreadCount,
    limit: Number(limit) || 20,
    offset: Number(offset) || 0,
    notifications: rows,
  };
};

/**
 * Get single notification by ID (verifying ownership)
 */
export const getNotificationById = async (userId, notificationId) => {
  const { rows } = await pool.query(
    'SELECT * FROM notifications WHERE notification_id = $1 AND user_id = $2',
    [notificationId, userId]
  );

  if (rows.length === 0) {
    throw new AppError('Notification not found', 404);
  }

  return rows[0];
};

/**
 * Create a new notification
 */
export const createNotification = async (currentUserId, data) => {
  const targetUserId = data.user_id || currentUserId;
  const { title, message, type = 'update' } = data;

  if (!title || !title.trim()) {
    throw new AppError('Title is required', 400);
  }
  if (!message || !message.trim()) {
    throw new AppError('Message is required', 400);
  }

  const { rows } = await pool.query(
    `INSERT INTO notifications (user_id, title, message, type, is_read)
     VALUES ($1, $2, $3, $4, FALSE)
     RETURNING *`,
    [targetUserId, title.trim(), message.trim(), type || 'update']
  );

  return rows[0];
};

/**
 * Update an existing notification
 */
export const updateNotification = async (userId, notificationId, data) => {
  const { title, message, type, is_read } = data;

  // Check existence
  const existing = await getNotificationById(userId, notificationId);

  const newTitle = title !== undefined ? title.trim() : existing.title;
  const newMessage = message !== undefined ? message.trim() : existing.message;
  const newType = type !== undefined ? type : existing.type;
  const newIsRead = is_read !== undefined ? (is_read === true || is_read === 'true') : existing.is_read;

  const { rows } = await pool.query(
    `UPDATE notifications
     SET title = $1, message = $2, type = $3, is_read = $4
     WHERE notification_id = $5 AND user_id = $6
     RETURNING *`,
    [newTitle, newMessage, newType, newIsRead, notificationId, userId]
  );

  return rows[0];
};

/**
 * Delete a notification
 */
export const deleteNotification = async (userId, notificationId) => {
  const result = await pool.query(
    'DELETE FROM notifications WHERE notification_id = $1 AND user_id = $2 RETURNING notification_id',
    [notificationId, userId]
  );

  if (result.rowCount === 0) {
    throw new AppError('Notification not found', 404);
  }

  return { message: 'Notification deleted successfully' };
};

/**
 * Mark a single notification as read
 */
export const markAsRead = async (userId, notificationId) => {
  const { rows } = await pool.query(
    `UPDATE notifications
     SET is_read = TRUE
     WHERE notification_id = $1 AND user_id = $2
     RETURNING *`,
    [notificationId, userId]
  );

  if (rows.length === 0) {
    throw new AppError('Notification not found', 404);
  }

  return rows[0];
};

/**
 * Mark all notifications as read for a user
 */
export const markAllAsRead = async (userId) => {
  const result = await pool.query(
    `UPDATE notifications
     SET is_read = TRUE
     WHERE user_id = $1 AND is_read = FALSE
     RETURNING notification_id`,
    [userId]
  );

  return {
    message: 'All notifications marked as read',
    updated_count: result.rowCount || 0,
  };
};

/**
 * Get unread notifications with count
 */
export const getUnreadNotifications = async (userId, options = {}) => {
  const { limit = 20, offset = 0 } = options;

  const countRes = await pool.query(
    'SELECT COUNT(*) FROM notifications WHERE user_id = $1 AND is_read = FALSE',
    [userId]
  );
  const unreadCount = parseInt(countRes.rows[0].count, 10) || 0;

  const { rows } = await pool.query(
    `SELECT * FROM notifications
     WHERE user_id = $1 AND is_read = FALSE
     ORDER BY created_at DESC
     LIMIT $2 OFFSET $3`,
    [userId, Number(limit) || 20, Number(offset) || 0]
  );

  return {
    unread_count: unreadCount,
    limit: Number(limit) || 20,
    offset: Number(offset) || 0,
    notifications: rows,
  };
};

/**
 * Send notification to single, multiple, or all users
 */
export const sendNotification = async (senderId, data) => {
  const { user_id, user_ids, broadcast, title, message, type = 'alert' } = data;

  if (!title || !title.trim()) {
    throw new AppError('Title is required', 400);
  }
  if (!message || !message.trim()) {
    throw new AppError('Message is required', 400);
  }

  if (broadcast === true || user_ids === 'all') {
    const result = await pool.query(
      `INSERT INTO notifications (user_id, title, message, type, is_read)
       SELECT user_id, $1, $2, $3, FALSE
       FROM users
       WHERE is_deleted = FALSE`,
      [title.trim(), message.trim(), type || 'alert']
    );

    return {
      message: 'Broadcast notification sent successfully',
      sent_count: result.rowCount || 0,
    };
  }

  if (Array.isArray(user_ids) && user_ids.length > 0) {
    let sentCount = 0;
    for (const uid of user_ids) {
      if (uid) {
        await pool.query(
          `INSERT INTO notifications (user_id, title, message, type, is_read)
           VALUES ($1, $2, $3, $4, FALSE)`,
          [uid, title.trim(), message.trim(), type || 'alert']
        );
        sentCount++;
      }
    }
    return {
      message: 'Notifications sent successfully',
      sent_count: sentCount,
    };
  }

  const targetId = user_id || senderId;
  const { rows } = await pool.query(
    `INSERT INTO notifications (user_id, title, message, type, is_read)
     VALUES ($1, $2, $3, $4, FALSE)
     RETURNING *`,
    [targetId, title.trim(), message.trim(), type || 'alert']
  );

  return {
    message: 'Notification sent successfully',
    sent_count: 1,
    notification: rows[0],
  };
};

/**
 * Get notification settings/preferences for a user
 */
export const getNotificationSettings = async (userId) => {
  let { rows } = await pool.query(
    'SELECT * FROM notification_preferences WHERE user_id = $1',
    [userId]
  );

  if (rows.length === 0) {
    const insertRes = await pool.query(
      `INSERT INTO notification_preferences (user_id, payment_reminders, payout_alerts, group_activity)
       VALUES ($1, TRUE, TRUE, TRUE)
       RETURNING *`,
      [userId]
    );
    rows = insertRes.rows;
  }

  return rows[0];
};

/**
 * Update notification settings/preferences for a user
 */
export const updateNotificationSettings = async (userId, data) => {
  const { payment_reminders, payout_alerts, group_activity } = data;

  const current = await getNotificationSettings(userId);

  const newPayment = payment_reminders !== undefined ? Boolean(payment_reminders) : current.payment_reminders;
  const newPayout = payout_alerts !== undefined ? Boolean(payout_alerts) : current.payout_alerts;
  const newGroup = group_activity !== undefined ? Boolean(group_activity) : current.group_activity;

  const { rows } = await pool.query(
    `INSERT INTO notification_preferences (user_id, payment_reminders, payout_alerts, group_activity, updated_at)
     VALUES ($1, $2, $3, $4, NOW())
     ON CONFLICT (user_id) DO UPDATE SET
       payment_reminders = EXCLUDED.payment_reminders,
       payout_alerts = EXCLUDED.payout_alerts,
       group_activity = EXCLUDED.group_activity,
       updated_at = NOW()
     RETURNING *`,
    [userId, newPayment, newPayout, newGroup]
  );

  return rows[0];
};

// Existing domain helper functions
export const notifyPaymentReminder = async (userId, groupName, amount, dueDate) => {
  await pool.query(
    `INSERT INTO notifications (user_id, title, message, type)
     VALUES ($1, $2, $3, 'payment_reminder')`,
    [
      userId,
      'Payment Reminder',
      `Your contribution of ${amount} ETB for ${groupName} is due on ${dueDate instanceof Date ? dueDate.toDateString() : dueDate}.`,
    ]
  );
};

export const notifyOverdueAlert = async (userId, adminId, groupName, amount) => {
  const message = `Contribution of ${amount} ETB for ${groupName} is overdue.`;
  await pool.query(
    `INSERT INTO notifications (user_id, title, message, type)
     VALUES ($1, 'Overdue Contribution', $2, 'overdue_alert')`,
    [userId, message]
  );
  if (adminId && adminId !== userId) {
    await pool.query(
      `INSERT INTO notifications (user_id, title, message, type)
       VALUES ($1, 'Overdue Contribution', $2, 'overdue_alert')`,
      [adminId, message]
    );
  }
};

export const notifyPayoutReceived = async (userId, amount, groupName) => {
  await pool.query(
    `INSERT INTO notifications (user_id, title, message, type)
     VALUES ($1, 'Payout Received', $2, 'payout_received')`,
    [userId, `You received ${amount} ETB from ${groupName}.`]
  );
};

export const notifyMemberJoined = async (adminId, memberName, groupName, currentCount) => {
  await pool.query(
    `INSERT INTO notifications (user_id, title, message, type)
     VALUES ($1, 'New Member', $2, 'group_activity')`,
    [adminId, `${memberName} joined ${groupName}. Members: ${currentCount}.`]
  );
};

export const notifyGroupStarted = async (groupId) => {
  await pool.query(
    `INSERT INTO notifications (user_id, title, message, type)
     SELECT gm.user_id, 'Group Started', 'Your Equb group has started. Contributions are now active.', 'group_activity'
     FROM group_members gm
     WHERE gm.group_id = $1 AND gm.status = 'active'`,
    [groupId]
  );
};

export const notifyGroupCompleted = async (groupId) => {
  await pool.query(
    `INSERT INTO notifications (user_id, title, message, type)
     SELECT gm.user_id, 'Group Completed', 'Your Equb group has completed all cycles. Congratulations!', 'group_completed'
     FROM group_members gm
     WHERE gm.group_id = $1 AND gm.status = 'active'`,
    [groupId]
  );
};
