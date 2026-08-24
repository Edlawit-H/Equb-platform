import { pool } from '../db/pool.js';
import { notifyPayoutReceived, notifyGroupCompleted } from './notification.service.js';

export const checkCycleComplete = async (groupId, cycleNumber) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { rows: groupRows } = await client.query(
      `SELECT contribution_amount, max_members, total_cycles, current_cycle, cycle_duration
       FROM equb_groups WHERE group_id = $1 AND status = 'active'`,
      [groupId]
    );
    if (groupRows.length === 0) {
      await client.query('ROLLBACK');
      return;
    }
    const group = groupRows[0];

    if (Number(group.current_cycle) !== Number(cycleNumber)) {
      await client.query('ROLLBACK');
      return;
    }

    const { rows: unpaidRows } = await client.query(
      `SELECT contribution_id FROM contributions
       WHERE group_id = $1 AND cycle_number = $2 AND status != 'paid'`,
      [groupId, cycleNumber]
    );
    if (unpaidRows.length > 0) {
      await client.query('ROLLBACK');
      return;
    }

    const { rows: payoutCheck } = await client.query(
      `SELECT payout_id FROM payouts
       WHERE group_id = $1 AND cycle_number = $2`,
      [groupId, cycleNumber]
    );
    if (payoutCheck.length > 0) {
      await client.query('ROLLBACK');
      return;
    }

    const { rows: memberRows } = await client.query(
      `SELECT COUNT(*) AS count FROM group_members
       WHERE group_id = $1 AND status = 'active'`,
      [groupId]
    );
    const activeCount = Number(memberRows[0].count);
    const payoutAmount = group.contribution_amount * activeCount;

    const { rows: winnerRows } = await client.query(
      `SELECT gm.member_id, gm.user_id
       FROM group_members gm
       WHERE gm.group_id = $1
         AND gm.status = 'active'
         AND NOT EXISTS (
           SELECT 1
           FROM payouts p
           WHERE p.group_id = gm.group_id
             AND p.member_id = gm.member_id
             AND p.status = 'completed'
         )
       ORDER BY RANDOM()
       LIMIT 1`,
      [groupId]
    );

    if (winnerRows.length === 0) {
      await client.query('ROLLBACK');
      return;
    }
    const winner = winnerRows[0];

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

    await client.query('COMMIT');

    await notifyPayoutReceived(winner.user_id, payoutAmount, groupId).catch(() => {});

  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

export const advanceCycle = async (groupId) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { rows: groupRows } = await client.query(
      `SELECT contribution_amount, max_members, total_cycles, current_cycle, cycle_duration, cycle_end_date
       FROM equb_groups WHERE group_id = $1 AND status = 'active'`,
      [groupId]
    );
    if (groupRows.length === 0) {
      await client.query('ROLLBACK');
      return;
    }
    const group = groupRows[0];

    const nextCycle = Number(group.current_cycle) + 1;
    const totalCycles = Number(group.total_cycles ?? group.max_members);

    if (nextCycle > totalCycles) {
      await client.query(
        `UPDATE equb_groups SET status = 'completed' WHERE group_id = $1`,
        [groupId]
      );
      await client.query('COMMIT');
      await notifyGroupCompleted(groupId).catch(() => {});
      return;
    }

    const prevCycleEnd = group.cycle_end_date
      ? new Date(group.cycle_end_date)
      : new Date();

    const nextCycleEnd = new Date(prevCycleEnd);
    nextCycleEnd.setDate(nextCycleEnd.getDate() + group.cycle_duration);

    await client.query(
      `UPDATE equb_groups
       SET current_cycle = $1, cycle_end_date = $2
       WHERE group_id = $3`,
      [nextCycle, nextCycleEnd.toISOString().split('T')[0], groupId]
    );

    await client.query(
      `INSERT INTO contributions (member_id, group_id, cycle_number, amount, due_date, status)
      SELECT member_id, $1, $2, $3, $4, 'pending'
       FROM group_members
       WHERE group_id = $1 AND status = 'active'`,
          [groupId, nextCycle, group.contribution_amount, nextCycleEnd.toISOString().split('T')[0]]
    );

    await client.query('COMMIT');

  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};
