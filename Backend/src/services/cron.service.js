import cron from 'node-cron';
import { pool } from '../db/pool.js';
import { notifyOverdueAlert, notifyPaymentReminder } from './notification.service.js';
import { advanceCycle } from './payout.service.js';

export const processPaymentReminders = async () => {
  try {
    const { rows } = await pool.query(
      `SELECT c.contribution_id, gm.user_id, eg.group_name, c.amount, c.due_date
       FROM contributions c
       JOIN group_members gm ON gm.member_id = c.member_id
       JOIN equb_groups eg ON eg.group_id = c.group_id
       WHERE c.status = 'pending'
         AND eg.status = 'active'
         AND c.due_date >= CURRENT_DATE
         AND c.due_date <= CURRENT_DATE + INTERVAL '2 days'
         AND NOT EXISTS (
           SELECT 1 FROM notifications n
           WHERE n.user_id = gm.user_id
             AND n.type = 'payment_reminder'
             AND n.created_at >= CURRENT_DATE
             AND n.message LIKE '%' || eg.group_name || '%'
         )`
    );
    for (const row of rows) {
      await notifyPaymentReminder(row.user_id, row.group_name, row.amount, new Date(row.due_date)).catch(() => {});
    }
  } catch (err) {
    console.error('Payment reminder error:', err.message);
  }
};

export const startCronJobs = () => {
  processPaymentReminders().catch(() => {});

  // Every hour: mark overdue contributions
  cron.schedule('0 * * * *', async () => {
    try {
      const { rows: overdueRows } = await pool.query(
        `UPDATE contributions SET status='overdue'
         WHERE due_date < CURRENT_DATE AND status='pending'
         RETURNING contribution_id, member_id, group_id, amount`
      );
      if (overdueRows.length === 0) return;

      const ids = overdueRows.map(r => r.contribution_id);
      const { rows } = await pool.query(
        `SELECT c.contribution_id, gm.user_id, eg.group_name, c.amount,
                admin_u.user_id AS admin_user_id
         FROM contributions c
         JOIN group_members gm ON gm.member_id = c.member_id
         JOIN equb_groups eg ON eg.group_id = c.group_id
         JOIN group_members admin_gm ON admin_gm.group_id = c.group_id AND admin_gm.role='admin'
         JOIN users admin_u ON admin_u.user_id = admin_gm.user_id
         WHERE c.contribution_id = ANY($1)`,
        [ids]
      );
      for (const row of rows) {
        await notifyOverdueAlert(row.user_id, row.admin_user_id, row.group_name, row.amount).catch(() => {});
      }
    } catch (err) {
      console.error('Overdue cron error:', err.message);
    }
  });

  // Daily at 9 AM: payment reminders
  cron.schedule('0 9 * * *', async () => {
    await processPaymentReminders();
  });

  // Every hour: advance cycle when cycle_end_date passed AND payout completed
  cron.schedule('30 * * * *', async () => {
    try {
      const { rows: expiredGroups } = await pool.query(
        `SELECT eg.group_id FROM equb_groups eg
         WHERE eg.status='active'
           AND eg.cycle_end_date < CURRENT_DATE
           AND EXISTS (
             SELECT 1 FROM payouts p
             WHERE p.group_id=eg.group_id
               AND p.cycle_number=eg.current_cycle
               AND p.status='completed'
           )`
      );
      for (const group of expiredGroups) {
        await advanceCycle(group.group_id).catch((err) => {
          console.error(`advanceCycle failed for group ${group.group_id}:`, err.message);
        });
      }
    } catch (err) {
      console.error('Cycle advance cron error:', err.message);
    }
  });
};