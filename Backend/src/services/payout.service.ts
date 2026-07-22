import { pool } from '../db/pool.js';
import { notifyPayoutReceived, notifyGroupCompleted } from './notification.service.js';

export const checkCycleComplete = async (groupId: string, cycleNumber: number): Promise<void> => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { rows: groupRows } = await client.query(
      `SELECT contribution_amount, max_members, current_cycle, cycle_duration
       FROM equb_groups WHERE group_id = $1`,
      [groupId]
    );
    if (groupRows.length === 0) return;
    const group = groupRows[0] as {
      contribution_amount: number;
      max_members: number;
      current_cycle: number;
      cycle_duration: number;
    };

    const { rows: unpaidRows } = await client.query(
      `SELECT contribution_id FROM contributions
       WHERE group_id = $1 AND cycle_number = $2 AND status != 'paid'`,
      [groupId, cycleNumber]
    );
    if (unpaidRows.length > 0) {
      await client.query('ROLLBACK');
      return;
    }

    const { rows: memberRows } = await client.query(
      `SELECT COUNT(*) AS count FROM group_members
       WHERE group_id = $1 AND status = 'active'`,
      [groupId]
    );
    const activeCount = Number((memberRows[0] as { count: string }).count);
    const payoutAmount = group.contribution_amount * activeCount;

    const { rows: winnerRows } = await client.query(
      `SELECT member_id, user_id FROM group_members
       WHERE group_id = $1 AND position_in_cycle = $2 AND status = 'active'`,
      [groupId, cycleNumber]
    );
    if (winnerRows.length === 0) {
      await client.query('ROLLBACK');
      return;
    }
    const winner = winnerRows[0] as { member_id: string; user_id: string };

    await client.query(
      `INSERT INTO payouts (group_id, member_id, payout_amount, cycle_number, status)
       VALUES ($1, $2, $3, $4, 'completed')`,
      [groupId, winner.member_id, payoutAmount, cycleNumber]
    );

    await client.query(
      `UPDATE users SET wallet_balance = wallet_balance + $1 WHERE user_id = $2`,
      [payoutAmount, winner.user_id]
    );

    await client.query(
      `INSERT INTO transactions (user_id, group_id, type, amount, status)
       VALUES ($1, $2, 'payout_credit', $3, 'completed')`,
      [winner.user_id, groupId, payoutAmount]
    );

    const nextCycle = group.current_cycle + 1;
    await client.query(
      `UPDATE equb_groups SET current_cycle = $1 WHERE group_id = $2`,
      [nextCycle, groupId]
    );

    if (nextCycle > group.max_members) {
      await client.query(
        `UPDATE equb_groups SET status = 'completed' WHERE group_id = $1`,
        [groupId]
      );
      await client.query('COMMIT');
      await notifyPayoutReceived(winner.user_id, payoutAmount, groupId);
      await notifyGroupCompleted(groupId);
      return;
    }

    const { rows: dueDateRows } = await client.query(
      `SELECT due_date FROM contributions
       WHERE group_id = $1 AND cycle_number = $2
       ORDER BY due_date DESC LIMIT 1`,
      [groupId, cycleNumber]
    );
    const lastDueDate = dueDateRows.length > 0
      ? new Date((dueDateRows[0] as { due_date: Date }).due_date)
      : new Date();
    const nextDueDate = new Date(lastDueDate);
    nextDueDate.setDate(nextDueDate.getDate() + group.cycle_duration);

    await client.query(
      `INSERT INTO contributions (member_id, group_id, cycle_number, amount, due_date, status)
       SELECT member_id, $1, $2, $3, $4, 'pending'
       FROM group_members WHERE group_id = $1 AND status = 'active'`,
      [groupId, nextCycle, group.contribution_amount, nextDueDate.toISOString().split('T')[0]]
    );

    await client.query('COMMIT');
    await notifyPayoutReceived(winner.user_id, payoutAmount, groupId);
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};
