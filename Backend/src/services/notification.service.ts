import { pool } from '../db/pool.js';

export const notifyPaymentReminder = async (
  userId: string,
  groupName: string,
  amount: number,
  dueDate: Date
): Promise<void> => {
  await pool.query(
    `INSERT INTO notifications (user_id, title, message, type)
     VALUES ($1, $2, $3, 'payment_reminder')`,
    [
      userId,
      'Payment Reminder',
      `Your contribution of ${amount} ETB for ${groupName} is due on ${dueDate.toDateString()}.`,
    ]
  );
};

export const notifyOverdueAlert = async (
  userId: string,
  adminId: string,
  groupName: string,
  amount: number
): Promise<void> => {
  const message = `Contribution of ${amount} ETB for ${groupName} is overdue.`;
  await pool.query(
    `INSERT INTO notifications (user_id, title, message, type)
     VALUES ($1, 'Overdue Contribution', $2, 'overdue_alert')`,
    [userId, message]
  );
  await pool.query(
    `INSERT INTO notifications (user_id, title, message, type)
     VALUES ($1, 'Overdue Contribution', $2, 'overdue_alert')`,
    [adminId, message]
  );
};

export const notifyPayoutReceived = async (
  userId: string,
  amount: number,
  groupName: string
): Promise<void> => {
  await pool.query(
    `INSERT INTO notifications (user_id, title, message, type)
     VALUES ($1, 'Payout Received', $2, 'payout_received')`,
    [userId, `You received ${amount} ETB from ${groupName}.`]
  );
};

export const notifyMemberJoined = async (
  adminId: string,
  memberName: string,
  groupName: string,
  currentCount: number
): Promise<void> => {
  await pool.query(
    `INSERT INTO notifications (user_id, title, message, type)
     VALUES ($1, 'New Member', $2, 'group_activity')`,
    [adminId, `${memberName} joined ${groupName}. Members: ${currentCount}.`]
  );
};

export const notifyGroupStarted = async (groupId: string): Promise<void> => {
  await pool.query(
    `INSERT INTO notifications (user_id, title, message, type)
     SELECT gm.user_id, 'Group Started', 'Your Equb group has started. Contributions are now active.', 'group_activity'
     FROM group_members gm
     WHERE gm.group_id = $1 AND gm.status = 'active'`,
    [groupId]
  );
};

export const notifyGroupCompleted = async (groupId: string): Promise<void> => {
  await pool.query(
    `INSERT INTO notifications (user_id, title, message, type)
     SELECT gm.user_id, 'Group Completed', 'Your Equb group has completed all cycles. Congratulations!', 'group_completed'
     FROM group_members gm
     WHERE gm.group_id = $1 AND gm.status = 'active'`,
    [groupId]
  );
};
