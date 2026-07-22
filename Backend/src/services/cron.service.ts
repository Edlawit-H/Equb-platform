import cron from 'node-cron';
import { pool } from '../db/pool.js';
import { notifyOverdueAlert, notifyPaymentReminder } from './notification.service.js';

export const startCronJobs = (): void => {
  cron.schedule('0 * * * *', async () => {
    await pool.query(
      `UPDATE contributions SET status = 'overdue'
       WHERE due_date < NOW() AND status = 'pending'`
    );

    const { rows } = await pool.query(
      `SELECT c.contribution_id, c.member_id, c.group_id, c.amount,
              gm.user_id, eg.group_name,
              u2.user_id AS admin_user_id
       FROM contributions c
       JOIN group_members gm ON gm.member_id = c.member_id
       JOIN equb_groups eg ON eg.group_id = c.group_id
       JOIN group_members admin_gm ON admin_gm.group_id = c.group_id AND admin_gm.role = 'admin'
       JOIN users u2 ON u2.user_id = admin_gm.user_id
       WHERE c.status = 'overdue'`
    );

    for (const row of rows as Array<{
      user_id: string;
      admin_user_id: string;
      group_name: string;
      amount: number;
    }>) {
      await notifyOverdueAlert(row.user_id, row.admin_user_id, row.group_name, row.amount);
    }
  });

  cron.schedule('0 9 * * *', async () => {
    const { rows } = await pool.query(
      `SELECT c.contribution_id, gm.user_id, eg.group_name, c.amount, c.due_date,
              EXTRACT(EPOCH FROM (c.due_date - NOW())) / 3600 AS hours_until_due
       FROM contributions c
       JOIN group_members gm ON gm.member_id = c.member_id
       JOIN equb_groups eg ON eg.group_id = c.group_id
       WHERE c.status = 'pending'
         AND c.due_date > NOW()
         AND EXTRACT(EPOCH FROM (c.due_date - NOW())) / 3600 BETWEEN 23 AND 49`
    );

    for (const row of rows as Array<{
      user_id: string;
      group_name: string;
      amount: number;
      due_date: Date;
    }>) {
      await notifyPaymentReminder(row.user_id, row.group_name, row.amount, new Date(row.due_date));
    }
  });
};
