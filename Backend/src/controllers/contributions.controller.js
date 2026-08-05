import { pool } from '../db/pool.js';
import { AppError } from '../utils/AppError.js';
import { asyncWrapper } from '../utils/asyncWrapper.js';
import { checkCycleComplete } from '../services/payout.service.js';

async function resolveMember(client, userId, groupId) {
  const { rows } = await client.query(
    `SELECT member_id FROM group_members
     WHERE user_id = $1 AND group_id = $2 AND status = 'active'`,
    [userId, groupId]
  );
  if (rows.length === 0) {
    throw new AppError('You are not an active member of this group', 403);
  }
  return rows[0].member_id;
}

async function writeAuditLog(client, userId, action, entityName, entityId) {
  await client.query(
    `INSERT INTO audit_logs (user_id, action, entity_name, entity_id)
     VALUES ($1, $2, $3, $4)`,
    [userId, action, entityName, entityId]
  );
}

// Pay contribution from wallet
export const payContribution = asyncWrapper(async (req, res) => {
  const { group_id, cycle_number } = req.body;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const memberId = await resolveMember(client, req.userId, group_id);

    const { rows: cRows } = await client.query(
      `SELECT contribution_id, amount, status
       FROM contributions
       WHERE member_id = $1 AND group_id = $2 AND cycle_number = $3`,
      [memberId, group_id, cycle_number]
    );
    if (cRows.length === 0) {
      throw new AppError('Contribution record not found', 404);
    }
    const contribution = cRows[0];
    if (contribution.status === 'paid') {
      throw new AppError('This contribution has already been paid', 409);
    }

    const amount = Number(contribution.amount);

    const { rows: walletRows } = await client.query(
      `SELECT wallet_balance FROM users WHERE user_id = $1 AND is_deleted = FALSE`,
      [req.userId]
    );
    if (walletRows.length === 0) throw new AppError('User not found', 404);
    if (Number(walletRows[0].wallet_balance) < amount) {
      throw new AppError('Insufficient wallet balance', 400);
    }

    await client.query(
      `UPDATE users SET wallet_balance = wallet_balance - $1 WHERE user_id = $2`,
      [amount, req.userId]
    );

    const now = new Date().toISOString();
    await client.query(
      `UPDATE contributions SET status = 'paid', paid_date = $1
       WHERE contribution_id = $2`,
      [now, contribution.contribution_id]
    );

    const { rows: txRows } = await client.query(
      `INSERT INTO transactions (user_id, group_id, type, amount, status)
       VALUES ($1, $2, 'contribution_debit', $3, 'completed')
       RETURNING transaction_id`,
      [req.userId, group_id, amount]
    );

    await writeAuditLog(
      client,
      req.userId,
      'contribution_recorded',
      'contributions',
      contribution.contribution_id
    );

    await client.query('COMMIT');

    checkCycleComplete(group_id, cycle_number).catch(() => {});

    res.status(200).json({
      status: 'success',
      message: 'Contribution paid successfully',
      data: {
        contribution_id: contribution.contribution_id,
        amount,
        transaction_id: txRows[0].transaction_id,
      },
    });
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
});

// List user contributions with pagination and filters
export const getContributions = asyncWrapper(async (req, res) => {
  const { group_id, status, page = '1', limit = '20' } = req.query;

  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 20));
  const offset = (pageNum - 1) * limitNum;

  const conditions = ['gm.user_id = $1'];
  const params = [req.userId];
  let i = 2;

  if (group_id) { conditions.push(`c.group_id = $${i++}`); params.push(group_id); }
  if (status)   { conditions.push(`c.status = $${i++}`);   params.push(status); }

  const where = conditions.join(' AND ');

  const [dataResult, countResult] = await Promise.all([
    pool.query(
      `SELECT
         c.contribution_id, c.cycle_number, c.amount, c.due_date,
         c.paid_date, c.status, c.created_at,
         eg.group_name, eg.group_id
       FROM contributions c
       JOIN group_members gm ON gm.member_id = c.member_id
       JOIN equb_groups   eg ON eg.group_id  = c.group_id
       WHERE ${where}
       ORDER BY c.due_date ASC
       LIMIT $${i} OFFSET $${i + 1}`,
      [...params, limitNum, offset]
    ),
    pool.query(
      `SELECT COUNT(*) AS total
       FROM contributions c
       JOIN group_members gm ON gm.member_id = c.member_id
       WHERE ${where}`,
      params
    ),
  ]);

  const total = parseInt(countResult.rows[0].total, 10);

  res.status(200).json({
    status: 'success',
    data: {
      contributions: dataResult.rows,
      pagination: {
        total,
        page: pageNum,
        limit: limitNum,
        total_pages: Math.ceil(total / limitNum),
      },
    },
  });
});

// List pending contributions for user
export const getPendingContributions = asyncWrapper(async (req, res) => {
  const { rows } = await pool.query(
    `SELECT
       c.contribution_id, c.cycle_number, c.amount, c.due_date, c.status,
       eg.group_name, eg.group_id
     FROM contributions c
     JOIN group_members gm ON gm.member_id = c.member_id
     JOIN equb_groups   eg ON eg.group_id  = c.group_id
     WHERE gm.user_id = $1 AND c.status IN ('pending', 'overdue')
     ORDER BY c.due_date ASC`,
    [req.userId]
  );

  res.status(200).json({
    status: 'success',
    data: { contributions: rows },
  });
});

// List overdue contributions for user
export const getOverdueContributions = asyncWrapper(async (req, res) => {
  const { rows } = await pool.query(
    `SELECT
       c.contribution_id, c.cycle_number, c.amount, c.due_date, c.status,
       eg.group_name, eg.group_id
     FROM contributions c
     JOIN group_members gm ON gm.member_id = c.member_id
     JOIN equb_groups   eg ON eg.group_id  = c.group_id
     WHERE gm.user_id = $1 AND c.status = 'overdue'
     ORDER BY c.due_date ASC`,
    [req.userId]
  );

  res.status(200).json({
    status: 'success',
    data: { contributions: rows },
  });
});

// Get contribution stats summary
export const getContributionStats = asyncWrapper(async (req, res) => {
  const { rows } = await pool.query(
    `SELECT
       c.status,
       COUNT(*)::int        AS count,
       SUM(c.amount)        AS total_amount
     FROM contributions c
     JOIN group_members gm ON gm.member_id = c.member_id
     WHERE gm.user_id = $1
     GROUP BY c.status`,
    [req.userId]
  );

  const stats = {
    pending:  { count: 0, total_amount: 0 },
    paid:     { count: 0, total_amount: 0 },
    overdue:  { count: 0, total_amount: 0 },
  };
  let totalPaid = 0;
  let totalAll = 0;

  for (const row of rows) {
    stats[row.status] = { count: row.count, total_amount: Number(row.total_amount) };
    if (row.status === 'paid') totalPaid = row.count;
    totalAll += row.count;
  }

  const onTimeRate = totalAll > 0 ? Math.round((totalPaid / totalAll) * 100) : 0;

  res.status(200).json({
    status: 'success',
    data: { stats, on_time_rate_percent: onTimeRate },
  });
});

// Get single contribution by ID
export const getContributionById = asyncWrapper(async (req, res) => {
  const { id } = req.params;

  const { rows } = await pool.query(
    `SELECT
       c.contribution_id, c.cycle_number, c.amount, c.due_date,
       c.paid_date, c.status, c.created_at,
       eg.group_name, eg.group_id,
       gm.user_id
     FROM contributions c
     JOIN group_members gm ON gm.member_id = c.member_id
     JOIN equb_groups   eg ON eg.group_id  = c.group_id
     WHERE c.contribution_id = $1`,
    [id]
  );

  if (rows.length === 0) throw new AppError('Contribution not found', 404);

  if (rows[0].user_id !== req.userId && req.userRole !== 'system_admin') {
    throw new AppError('Forbidden', 403);
  }

  res.status(200).json({
    status: 'success',
    data: { contribution: rows[0] },
  });
});

// Get all contributions for a group
export const getGroupContributions = asyncWrapper(async (req, res) => {
  const { id: groupId } = req.params;
  const { cycle_number, status, page = '1', limit = '20' } = req.query;

  const { rows: memberCheck } = await pool.query(
    `SELECT member_id FROM group_members
     WHERE user_id = $1 AND group_id = $2 AND status = 'active'`,
    [req.userId, groupId]
  );
  if (memberCheck.length === 0) throw new AppError('You are not a member of this group', 403);

  const pageNum  = Math.max(1, parseInt(page, 10)  || 1);
  const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 20));
  const offset   = (pageNum - 1) * limitNum;

  const conditions = ['c.group_id = $1'];
  const params = [groupId];
  let i = 2;

  if (cycle_number) { conditions.push(`c.cycle_number = $${i++}`); params.push(cycle_number); }
  if (status)       { conditions.push(`c.status = $${i++}`);       params.push(status); }

  const where = conditions.join(' AND ');

  const [dataResult, countResult] = await Promise.all([
    pool.query(
      `SELECT
         c.contribution_id, c.cycle_number, c.amount, c.due_date,
         c.paid_date, c.status,
         u.full_name AS member_name, gm.member_id
       FROM contributions c
       JOIN group_members gm ON gm.member_id = c.member_id
       JOIN users         u  ON u.user_id    = gm.user_id
       WHERE ${where}
       ORDER BY c.cycle_number ASC, c.due_date ASC
       LIMIT $${i} OFFSET $${i + 1}`,
      [...params, limitNum, offset]
    ),
    pool.query(
      `SELECT COUNT(*) AS total FROM contributions c WHERE ${where}`,
      params
    ),
  ]);

  res.status(200).json({
    status: 'success',
    data: {
      contributions: dataResult.rows,
      pagination: {
        total: parseInt(countResult.rows[0].total, 10),
        page: pageNum,
        limit: limitNum,
        total_pages: Math.ceil(parseInt(countResult.rows[0].total, 10) / limitNum),
      },
    },
  });
});

// Admin update contribution
export const updateContribution = asyncWrapper(async (req, res) => {
  if (req.userRole !== 'system_admin') throw new AppError('Forbidden', 403);

  const { id } = req.params;
  const { status, paid_date } = req.body;

  const allowed = ['pending', 'paid', 'overdue'];
  if (!allowed.includes(status)) {
    throw new AppError(`status must be one of: ${allowed.join(', ')}`, 400);
  }

  const { rows } = await pool.query(
    `UPDATE contributions SET status = $1, paid_date = $2
     WHERE contribution_id = $3
     RETURNING *`,
    [status, paid_date ?? null, id]
  );
  if (rows.length === 0) throw new AppError('Contribution not found', 404);

  res.status(200).json({ status: 'success', data: { contribution: rows[0] } });
});

// Admin reset contribution to pending
export const deleteContribution = asyncWrapper(async (req, res) => {
  if (req.userRole !== 'system_admin') throw new AppError('Forbidden', 403);

  const { id } = req.params;

  const { rows } = await pool.query(
    `UPDATE contributions SET status = 'pending', paid_date = NULL
     WHERE contribution_id = $1 RETURNING contribution_id`,
    [id]
  );
  if (rows.length === 0) throw new AppError('Contribution not found', 404);

  res.status(200).json({ status: 'success', message: 'Contribution reset to pending' });
});

// Admin bulk mark contributions as paid
export const bulkContributions = asyncWrapper(async (req, res) => {
  if (req.userRole !== 'system_admin') throw new AppError('Forbidden', 403);

  const { group_id, cycle_number, member_ids } = req.body;
  const now = new Date().toISOString();

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const results = [];

    for (const memberId of member_ids) {
      const { rows } = await client.query(
        `UPDATE contributions SET status = 'paid', paid_date = $1
         WHERE member_id = $2 AND group_id = $3 AND cycle_number = $4
           AND status != 'paid'
         RETURNING contribution_id, amount`,
        [now, memberId, group_id, cycle_number]
      );

      if (rows.length > 0) {
        const { rows: uRows } = await client.query(
          `SELECT user_id FROM group_members WHERE member_id = $1`,
          [memberId]
        );
        if (uRows.length > 0) {
          await client.query(
            `UPDATE users SET wallet_balance = wallet_balance - $1 WHERE user_id = $2`,
            [rows[0].amount, uRows[0].user_id]
          );
          await client.query(
            `INSERT INTO transactions (user_id, group_id, type, amount, status)
             VALUES ($1, $2, 'contribution_debit', $3, 'completed')`,
            [uRows[0].user_id, group_id, rows[0].amount]
          );
        }
        results.push(rows[0].contribution_id);
      }
    }

    await writeAuditLog(client, req.userId, 'bulk_contributions_recorded', 'contributions', group_id);

    await client.query('COMMIT');

    checkCycleComplete(group_id, cycle_number).catch(() => {});

    res.status(200).json({
      status: 'success',
      message: `${results.length} contribution(s) marked as paid`,
      data: { updated_ids: results },
    });
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
});

// Admin manual contribution record
export const manualContribution = asyncWrapper(async (req, res) => {
  if (req.userRole !== 'system_admin') throw new AppError('Forbidden', 403);

  const { member_id, group_id, cycle_number, paid_date } = req.body;
  const now = paid_date ?? new Date().toISOString();

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { rows } = await client.query(
      `UPDATE contributions SET status = 'paid', paid_date = $1
       WHERE member_id = $2 AND group_id = $3 AND cycle_number = $4
         AND status != 'paid'
       RETURNING contribution_id, amount`,
      [now, member_id, group_id, cycle_number]
    );

    if (rows.length === 0) {
      throw new AppError('Contribution not found or already paid', 404);
    }

    await writeAuditLog(
      client,
      req.userId,
      'contribution_recorded',
      'contributions',
      rows[0].contribution_id
    );

    await client.query('COMMIT');

    checkCycleComplete(group_id, cycle_number).catch(() => {});

    res.status(200).json({
      status: 'success',
      message: 'Contribution manually recorded',
      data: { contribution_id: rows[0].contribution_id },
    });
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
});
