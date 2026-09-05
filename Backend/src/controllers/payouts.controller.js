import { pool } from '../db/pool.js';
import { AppError } from '../utils/AppError.js';
import { asyncWrapper } from '../utils/asyncWrapper.js';
import { notifyPayoutReceived, notifyGroupCompleted } from '../services/notification.service.js';

async function writeAuditLog(client, userId, action, entityName, entityId) {
  await client.query(
    `INSERT INTO audit_logs (user_id, action, entity_name, entity_id)
     VALUES ($1, $2, $3, $4)`,
    [userId, action, entityName, entityId]
  );
}

// Get authenticated user's payouts
export const getMyPayouts = asyncWrapper(async (req, res) => {
  const { group_id, status, page = '1', limit = '20' } = req.query;

  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 20));
  const offset = (pageNum - 1) * limitNum;

  const conditions = ['gm.user_id = $1'];
  const params = [req.userId];
  let i = 2;

  if (group_id) {
    conditions.push(`p.group_id = $${i++}`);
    params.push(group_id);
  }
  if (status) {
    conditions.push(`p.status = $${i++}`);
    params.push(status);
  }

  const where = conditions.join(' AND ');

  const [dataResult, countResult] = await Promise.all([
    pool.query(
      `SELECT
         p.payout_id,
         p.group_id,
         eg.group_name,
         p.member_id,
         p.payout_amount,
         p.payout_date,
         p.cycle_number,
         p.status,
         p.created_at
       FROM payouts p
       JOIN group_members gm ON gm.member_id = p.member_id
       JOIN equb_groups eg ON eg.group_id = p.group_id
       WHERE ${where}
       ORDER BY p.payout_date DESC
       LIMIT $${i} OFFSET $${i + 1}`,
      [...params, limitNum, offset]
    ),
    pool.query(
      `SELECT COUNT(*) AS total
       FROM payouts p
       JOIN group_members gm ON gm.member_id = p.member_id
       WHERE ${where}`,
      params
    ),
  ]);

  const total = parseInt(countResult.rows[0].total, 10);

  res.status(200).json({
    status: 'success',
    data: {
      payouts: dataResult.rows,
      pagination: {
        total,
        page: pageNum,
        limit: limitNum,
        total_pages: Math.ceil(total / limitNum),
      },
    },
  });
});

// Get completed payout history for user
export const getPayoutHistory = asyncWrapper(async (req, res) => {
  const { page = '1', limit = '20' } = req.query;

  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 20));
  const offset = (pageNum - 1) * limitNum;

  const [dataResult, countResult] = await Promise.all([
    pool.query(
      `SELECT
         p.payout_id,
         p.group_id,
         eg.group_name,
         p.payout_amount,
         p.payout_date,
         p.cycle_number,
         p.status
       FROM payouts p
       JOIN group_members gm ON gm.member_id = p.member_id
       JOIN equb_groups eg ON eg.group_id = p.group_id
       WHERE gm.user_id = $1 AND p.status = 'completed'
       ORDER BY p.payout_date DESC
       LIMIT $2 OFFSET $3`,
      [req.userId, limitNum, offset]
    ),
    pool.query(
      `SELECT COUNT(*) AS total
       FROM payouts p
       JOIN group_members gm ON gm.member_id = p.member_id
       WHERE gm.user_id = $1 AND p.status = 'completed'`,
      [req.userId]
    ),
  ]);

  const total = parseInt(countResult.rows[0].total, 10);

  res.status(200).json({
    status: 'success',
    data: {
      payouts: dataResult.rows,
      pagination: {
        total,
        page: pageNum,
        limit: limitNum,
        total_pages: Math.ceil(total / limitNum),
      },
    },
  });
});

// Get projected payout schedule for user's active groups
export const getPayoutSchedule = asyncWrapper(async (req, res) => {
  const { rows } = await pool.query(
    `SELECT
       gm.group_id,
       gm.member_id,
       eg.group_name,
       gm.position_in_cycle,
       eg.current_cycle,
       eg.total_cycles,
       eg.contribution_amount,
       eg.cycle_duration,
       eg.max_members,
      eg.start_date,
      eg.cycle_end_date,
       eg.status AS group_status,
       (
         SELECT COUNT(*)::int FROM group_members
         WHERE group_id = eg.group_id AND status = 'active'
       ) AS active_members_count,
       p.payout_id,
       p.cycle_number AS paid_cycle_number,
       p.status AS payout_status,
       p.payout_date
     FROM group_members gm
     JOIN equb_groups eg ON eg.group_id = gm.group_id
     LEFT JOIN payouts p ON p.group_id = gm.group_id AND p.member_id = gm.member_id AND p.status IN ('completed', 'pending')
     WHERE gm.user_id = $1 AND gm.status = 'active' AND eg.is_deleted = FALSE
     ORDER BY eg.created_at DESC`,
    [req.userId]
  );

  const schedule = rows.map((row) => {
    const activeCount = row.active_members_count || row.max_members;
    const estimatedPayoutAmount = Number(row.contribution_amount) * activeCount;

    const effectiveCycle = row.paid_cycle_number || row.position_in_cycle;

    let projectedDate = null;
    if (row.payout_date) {
      projectedDate = new Date(row.payout_date).toISOString().split('T')[0];
    } else if (row.start_date) {
      const start = new Date(row.start_date);
      const daysToAdd = (effectiveCycle - 1) * row.cycle_duration;
      start.setDate(start.getDate() + daysToAdd);
      projectedDate = start.toISOString().split('T')[0];
    }

    let payoutStatus = 'upcoming';
    if (row.payout_status === 'completed' || effectiveCycle < row.current_cycle) {
      payoutStatus = 'completed';
    } else if (effectiveCycle === row.current_cycle) {
      payoutStatus = row.payout_status === 'pending' ? 'pending_approval' : 'current';
    }

    return {
      group_id: row.group_id,
      group_name: row.group_name,
      position_in_cycle: effectiveCycle,
      current_cycle: row.current_cycle,
      total_cycles: row.total_cycles || row.active_members_count,
      projected_date: projectedDate,
      estimated_payout_amount: estimatedPayoutAmount,
      status: payoutStatus,
      group_status: row.group_status,
    };
  });

  res.status(200).json({
    status: 'success',
    data: { schedule },
  });
});

// Get single payout detail by ID
export const getPayoutById = asyncWrapper(async (req, res) => {
  const { id } = req.params;

  const { rows } = await pool.query(
    `SELECT
       p.payout_id,
       p.group_id,
       eg.group_name,
       p.member_id,
       u.full_name AS recipient_name,
       gm.user_id AS recipient_user_id,
       p.payout_amount,
       p.payout_date,
       p.cycle_number,
       p.status,
       p.created_at
     FROM payouts p
     JOIN group_members gm ON gm.member_id = p.member_id
     JOIN users u ON u.user_id = gm.user_id
     JOIN equb_groups eg ON eg.group_id = p.group_id
     WHERE p.payout_id = $1`,
    [id]
  );

  if (rows.length === 0) {
    throw new AppError('Payout not found', 404);
  }

  const payout = rows[0];

  if (payout.recipient_user_id !== req.userId && req.userRole !== 'system_admin') {
    throw new AppError('Forbidden', 403);
  }

  res.status(200).json({
    status: 'success',
    data: { payout },
  });
});

// Get all payouts for a group
export const getGroupPayouts = asyncWrapper(async (req, res) => {
  const groupId = req.params.groupId || req.params.id;
  const { page = '1', limit = '50' } = req.query;

  if (req.userRole !== 'system_admin') {
    const { rows: memberCheck } = await pool.query(
      `SELECT gm.member_id FROM group_members gm
       WHERE gm.user_id = $1 AND gm.group_id = $2 AND gm.status = 'active'`,
      [req.userId, groupId]
    );
    if (memberCheck.length === 0) {
      const { rows: adminCheck } = await pool.query(
        `SELECT group_id FROM equb_groups WHERE group_id = $1 AND admin_id = $2`,
        [groupId, req.userId]
      );
      if (adminCheck.length === 0) {
        throw new AppError('You are not a member of this group', 403);
      }
    }
  }

  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 50));
  const offset = (pageNum - 1) * limitNum;

  const [dataResult, countResult] = await Promise.all([
    pool.query(
      `SELECT
         p.payout_id,
         p.group_id,
         p.member_id,
         u.full_name AS recipient_name,
         p.payout_amount,
         p.payout_date,
         p.cycle_number,
         p.status
       FROM payouts p
       JOIN group_members gm ON gm.member_id = p.member_id
       JOIN users u ON u.user_id = gm.user_id
       WHERE p.group_id = $1
       ORDER BY p.cycle_number ASC
       LIMIT $2 OFFSET $3`,
      [groupId, limitNum, offset]
    ),
    pool.query(
      `SELECT COUNT(*) AS total FROM payouts WHERE group_id = $1`,
      [groupId]
    ),
  ]);

  const total = parseInt(countResult.rows[0].total, 10);

  res.status(200).json({
    status: 'success',
    data: {
      payouts: dataResult.rows,
      pagination: {
        total,
        page: pageNum,
        limit: limitNum,
        total_pages: Math.ceil(total / limitNum),
      },
    },
  });
});

// Admin manual approve for pending payout
export const approvePayout = asyncWrapper(async (req, res) => {
  const { id } = req.params;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { rows: payoutRows } = await client.query(
      `SELECT p.payout_id, p.group_id, p.member_id, p.payout_amount, p.cycle_number, p.status,
              gm.user_id, eg.admin_id
       FROM payouts p
       JOIN group_members gm ON gm.member_id = p.member_id
       JOIN equb_groups eg ON eg.group_id = p.group_id
       WHERE p.payout_id = $1`,
      [id]
    );

    if (payoutRows.length === 0) {
      throw new AppError('Payout not found', 404);
    }

    const payout = payoutRows[0];

    if (req.userRole !== 'system_admin' && payout.admin_id !== req.userId) {
      throw new AppError('Only the group admin or system admin can approve payouts', 403);
    }

    if (payout.status !== 'pending') {
      throw new AppError(`Cannot approve payout with status '${payout.status}'`, 400);
    }

    // Block approval if any member hasn't paid yet — same rule as automatic flow
    const { rows: unpaidRows } = await client.query(
      `SELECT contribution_id FROM contributions
       WHERE group_id = $1 AND cycle_number = $2 AND status != 'paid'`,
      [payout.group_id, payout.cycle_number]
    );

    if (unpaidRows.length > 0) {
      throw new AppError('Cannot approve payout until all members have paid for this cycle', 400);
    }

    const now = new Date().toISOString();

    await client.query(
      `UPDATE payouts SET status = 'completed', payout_date = $1 WHERE payout_id = $2`,
      [now, id]
    );

    const payoutAmount = Number(payout.payout_amount);
    await client.query(
      `UPDATE users SET wallet_balance = wallet_balance + $1 WHERE user_id = $2`,
      [payoutAmount, payout.user_id]
    );

    await client.query(
      `INSERT INTO transactions (user_id, group_id, type, amount, status)
       VALUES ($1, $2, 'payout_credit', $3, 'completed')`,
      [payout.user_id, payout.group_id, payoutAmount]
    );

    // Check if every active member has now received a payout.
    // Completion is tied ONLY to all members having been paid — no date or cycle guards.
    const { rows: unpaidMembers } = await client.query(
      `SELECT gm.member_id
       FROM group_members gm
       WHERE gm.group_id = $1
         AND gm.status = 'active'
         AND NOT EXISTS (
           SELECT 1 FROM payouts p
           WHERE p.group_id = gm.group_id
             AND p.member_id = gm.member_id
             AND p.status = 'completed'
         )`,
      [payout.group_id]
    );

    const allPaid = unpaidMembers.length === 0;

    if (allPaid) {
      await client.query(
        `UPDATE equb_groups SET status = 'completed' WHERE group_id = $1`,
        [payout.group_id]
      );
    }

    await writeAuditLog(client, req.userId, 'payout_approved', 'payouts', id);

    await client.query('COMMIT');

    notifyPayoutReceived(payout.user_id, payoutAmount, payout.group_id).catch(() => {});
    if (allPaid) {
      notifyGroupCompleted(payout.group_id).catch(() => {});
    }

    res.status(200).json({
      status: 'success',
      message: 'Payout approved and completed successfully',
      data: { payout_id: id, status: 'completed' },
    });
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
});

// Admin reject pending payout
export const rejectPayout = asyncWrapper(async (req, res) => {
  const { id } = req.params;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { rows: payoutRows } = await client.query(
      `SELECT p.payout_id, p.status, eg.admin_id
       FROM payouts p
       JOIN equb_groups eg ON eg.group_id = p.group_id
       WHERE p.payout_id = $1`,
      [id]
    );

    if (payoutRows.length === 0) {
      throw new AppError('Payout not found', 404);
    }

    const payout = payoutRows[0];
    if (req.userRole !== 'system_admin' && payout.admin_id !== req.userId) {
      throw new AppError('Only the group admin or system admin can reject payouts', 403);
    }

    if (payout.status !== 'pending') {
      throw new AppError(`Cannot reject payout with status '${payout.status}'`, 400);
    }

    await client.query(
      `UPDATE payouts SET status = 'rejected' WHERE payout_id = $1`,
      [id]
    );

    await writeAuditLog(client, req.userId, 'payout_rejected', 'payouts', id);

    await client.query('COMMIT');

    res.status(200).json({
      status: 'success',
      message: 'Payout rejected successfully',
      data: { payout_id: id, status: 'rejected' },
    });
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
});

// Admin update payout
export const updatePayout = asyncWrapper(async (req, res) => {
  if (req.userRole !== 'system_admin') {
    throw new AppError('Forbidden', 403);
  }

  const { id } = req.params;
  const { status, payout_amount } = req.body;

  const updates = [];
  const params = [];
  let i = 1;

  if (status) {
    updates.push(`status = $${i++}`);
    params.push(status);
  }
  if (payout_amount !== undefined) {
    updates.push(`payout_amount = $${i++}`);
    params.push(payout_amount);
  }

  if (updates.length === 0) {
    throw new AppError('No fields to update', 400);
  }

  params.push(id);
  const { rows } = await pool.query(
    `UPDATE payouts SET ${updates.join(', ')} WHERE payout_id = $${i} RETURNING *`,
    params
  );

  if (rows.length === 0) {
    throw new AppError('Payout not found', 404);
  }

  res.status(200).json({
    status: 'success',
    data: { payout: rows[0] },
  });
});

// Admin delete/reject payout
export const deletePayout = asyncWrapper(async (req, res) => {
  if (req.userRole !== 'system_admin') {
    throw new AppError('Forbidden', 403);
  }

  const { id } = req.params;

  const { rows } = await pool.query(
    `UPDATE payouts SET status = 'rejected' WHERE payout_id = $1 RETURNING payout_id`,
    [id]
  );

  if (rows.length === 0) {
    throw new AppError('Payout not found', 404);
  }

  res.status(200).json({
    status: 'success',
    message: 'Payout cancelled/rejected by admin',
  });
});

// Get full payout rotation schedule for a group (all cycles, all members)
export const getGroupPayoutSchedule = asyncWrapper(async (req, res) => {
  const groupId = req.params.groupId || req.params.id;

  // Verify the requesting user is a member or admin of this group
  const { rows: accessCheck } = await pool.query(
    `SELECT gm.member_id FROM group_members gm
     WHERE gm.user_id = $1 AND gm.group_id = $2 AND gm.status = 'active'
     UNION
     SELECT group_id FROM equb_groups WHERE group_id = $1 AND admin_id = $2`,
    [req.userId, groupId]
  );

  if (accessCheck.length === 0 && req.userRole !== 'system_admin') {
    throw new AppError('You are not a member of this group', 403);
  }

  // Fetch group info
  const { rows: groupRows } = await pool.query(
        `SELECT group_id, group_name, contribution_amount, cycle_duration,
          current_cycle, total_cycles, max_members, start_date, cycle_end_date, status
     FROM equb_groups WHERE group_id = $1 AND is_deleted = FALSE`,
    [groupId]
  );

  if (groupRows.length === 0) {
    throw new AppError('Group not found', 404);
  }

  const group = groupRows[0];
  const totalCycles = Number(group.total_cycles ?? group.max_members ?? 1);
  const currentCycle = Number(group.current_cycle ?? 1);
  const cycleDuration = Number(group.cycle_duration ?? 7);
  const contributionAmount = Number(group.contribution_amount ?? 0);

  // Fetch all active members ordered by position
  const { rows: members } = await pool.query(
    `SELECT gm.member_id, gm.position_in_cycle, u.full_name, u.phone_number
     FROM group_members gm
     JOIN users u ON u.user_id = gm.user_id
     WHERE gm.group_id = $1 AND gm.status = 'active'
     ORDER BY gm.position_in_cycle ASC`,
    [groupId]
  );

  // Fetch all payouts for this group
  const { rows: payouts } = await pool.query(
    `SELECT p.payout_id, p.cycle_number, p.payout_amount, p.payout_date, p.status,
            p.member_id, u.full_name AS recipient_name, u.phone_number AS recipient_phone
     FROM payouts p
     JOIN group_members gm ON gm.member_id = p.member_id
     JOIN users u ON u.user_id = gm.user_id
     WHERE p.group_id = $1
     ORDER BY p.cycle_number ASC`,
    [groupId]
  );

  // Index existing payouts by cycle number and track already-paid members
  const payoutByCycle = new Map();
  const paidMemberIds = new Set();
  for (const p of payouts) {
    payoutByCycle.set(Number(p.cycle_number), p);
    if (p.status === 'completed' || p.status === 'pending') {
      paidMemberIds.add(p.member_id);
    }
  }

  // Active members who have not yet received any payout, ordered by position
  const unpaidMembers = members.filter((m) => !paidMemberIds.has(m.member_id));
  let unpaidIdx = 0;

  const estimatedPayout = contributionAmount * members.length;
  const startDate = group.start_date ? new Date(group.start_date) : null;

  // Build one entry per cycle without duplicate recipients
  const schedule = [];
  const effectiveTotal = Math.max(totalCycles, members.length);

  const { rows: cycleStartRows } = await pool.query(
    `SELECT cycle_number, MIN(created_at) AS cycle_started_at
     FROM contributions
     WHERE group_id = $1
     GROUP BY cycle_number`,
    [groupId]
  );
  const cycleStartByNumber = new Map(
    cycleStartRows.map((row) => [Number(row.cycle_number), row.cycle_started_at])
  );

  for (let cycle = 1; cycle <= effectiveTotal; cycle++) {
    const existingPayout = payoutByCycle.get(cycle);

    let recipientName = null;
    let recipientPhone = null;
    let payoutAmount = estimatedPayout;
    let payoutDate = null;
    let status = 'upcoming';
    let payoutId = null;

    if (existingPayout) {
      recipientName = existingPayout.recipient_name;
      recipientPhone = existingPayout.recipient_phone;
      payoutAmount = Number(existingPayout.payout_amount) || estimatedPayout;
      payoutDate = existingPayout.payout_date
        ? new Date(existingPayout.payout_date).toISOString().split('T')[0]
        : null;
      status = existingPayout.status === 'completed' ? 'completed' : 'current';
      payoutId = existingPayout.payout_id;
    } else {
      // Assign the next member who hasn't received a payout yet
      const nextMember = unpaidMembers[unpaidIdx++];
      if (nextMember) {
        recipientName = nextMember.full_name;
        recipientPhone = nextMember.phone_number;
      } else {
        recipientName = `Member #${cycle}`;
      }

      if (cycle < currentCycle) {
        status = 'completed';
      } else if (cycle === currentCycle) {
        status = 'current';
      } else {
        status = 'upcoming';
      }
    }

    // Projected date: best-case estimation for when this cycle's payout will arrive.
    // For completed cycles, shows the actual payout date.
    // For upcoming cycles, projects forward from current cycle_end_date so delays shift realistic expectations.
    let projectedDate = payoutDate;
    if (!projectedDate) {
      if (cycle === currentCycle && group.cycle_end_date) {
        projectedDate = new Date(group.cycle_end_date).toISOString().split('T')[0];
      } else if (cycle > currentCycle && group.cycle_end_date) {
        const d = new Date(group.cycle_end_date);
        d.setDate(d.getDate() + (cycle - currentCycle) * cycleDuration);
        projectedDate = d.toISOString().split('T')[0];
      } else if (startDate) {
        const d = new Date(startDate);
        d.setDate(d.getDate() + (cycle - 1) * cycleDuration);
        projectedDate = d.toISOString().split('T')[0];
      }
    }

    schedule.push({
      cycle_number: cycle,
      cycle_started_at: cycleStartByNumber.get(cycle)
        ? new Date(cycleStartByNumber.get(cycle)).toISOString()
        : null,
      total_cycles: effectiveTotal,
      current_cycle: currentCycle,
      recipient_name: recipientName,
      recipient_phone: recipientPhone,
      projected_date: projectedDate ?? 'Pending Start',
      payout_amount: payoutAmount,
      status,
      payout_id: payoutId,
    });
  }

  res.status(200).json({
    status: 'success',
    data: {
      group_id: group.group_id,
      group_name: group.group_name,
      group_status: group.status,
      current_cycle: currentCycle,
      total_cycles: effectiveTotal,
      cycle_duration: cycleDuration,
      contribution_amount: contributionAmount,
      estimated_payout_per_cycle: estimatedPayout,
      schedule,
    },
  });
});