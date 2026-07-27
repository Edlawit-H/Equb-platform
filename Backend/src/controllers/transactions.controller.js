import { pool } from '../db/pool.js';
import { AppError } from '../utils/AppError.js';
import { asyncWrapper } from '../utils/asyncWrapper.js';

// GET /api/v1/transactions/wallet
// Returns the authenticated user's wallet balance
export const getWallet = asyncWrapper(async (req, res) => {
  const { rows } = await pool.query(
    `SELECT user_id, full_name, wallet_balance FROM users WHERE user_id = $1 AND is_deleted = FALSE`,
    [req.userId]
  );

  if (rows.length === 0) {
    throw new AppError('User not found', 404);
  }

  res.status(200).json({
    status: 'success',
    data: {
      user_id: rows[0].user_id,
      full_name: rows[0].full_name,
      wallet_balance: Number(rows[0].wallet_balance),
    },
  });
});

// POST /api/v1/transactions/top-up
// Simulates adding funds to user's wallet
export const topUpWallet = asyncWrapper(async (req, res) => {
  const { amount } = req.body;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Credit the user's wallet
    const { rows: userRows } = await client.query(
      `UPDATE users
       SET wallet_balance = wallet_balance + $1
       WHERE user_id = $2 AND is_deleted = FALSE
       RETURNING user_id, full_name, wallet_balance`,
      [amount, req.userId]
    );

    if (userRows.length === 0) {
      throw new AppError('User not found', 404);
    }

    // Record the transaction
    const { rows: txRows } = await client.query(
      `INSERT INTO transactions (user_id, type, amount, status)
       VALUES ($1, 'top_up', $2, 'completed')
       RETURNING transaction_id, type, amount, status, created_at`,
      [req.userId, amount]
    );

    await client.query('COMMIT');

    res.status(201).json({
      status: 'success',
      message: 'Wallet topped up successfully',
      data: {
        transaction: txRows[0],
        new_balance: Number(userRows[0].wallet_balance),
      },
    });
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
});

// GET /api/v1/transactions
// Returns paginated transaction history for authenticated user with optional filters
export const getTransactions = asyncWrapper(async (req, res) => {
  const { type, group_id, from, to, page = '1', limit = '20' } = req.query;

  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 20));
  const offset = (pageNum - 1) * limitNum;

  const conditions = ['t.user_id = $1'];
  const params = [req.userId];
  let paramIndex = 2;

  if (type) {
    conditions.push(`t.type = $${paramIndex++}`);
    params.push(type);
  }
  if (group_id) {
    conditions.push(`t.group_id = $${paramIndex++}`);
    params.push(group_id);
  }
  if (from) {
    conditions.push(`t.created_at >= $${paramIndex++}`);
    params.push(from);
  }
  if (to) {
    conditions.push(`t.created_at <= $${paramIndex++}`);
    params.push(to);
  }

  const whereClause = conditions.join(' AND ');

  const [txResult, countResult] = await Promise.all([
    pool.query(
      `SELECT
         t.transaction_id,
         t.type,
         t.amount,
         t.status,
         t.reference_number,
         t.created_at,
         eg.group_name
       FROM transactions t
       LEFT JOIN equb_groups eg ON eg.group_id = t.group_id
       WHERE ${whereClause}
       ORDER BY t.created_at DESC
       LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`,
      [...params, limitNum, offset]
    ),
    pool.query(
      `SELECT COUNT(*) AS total FROM transactions t WHERE ${whereClause}`,
      params
    ),
  ]);

  const total = parseInt(countResult.rows[0].total, 10);

  res.status(200).json({
    status: 'success',
    data: {
      transactions: txResult.rows,
      pagination: {
        total,
        page: pageNum,
        limit: limitNum,
        total_pages: Math.ceil(total / limitNum),
      },
    },
  });
});

// GET /api/v1/transactions/:id
// Returns a single transaction by ID (must belong to the authenticated user)
export const getTransactionById = asyncWrapper(async (req, res) => {
  const { id } = req.params;

  const { rows } = await pool.query(
    `SELECT
       t.transaction_id,
       t.type,
       t.amount,
       t.status,
       t.reference_number,
       t.created_at,
       eg.group_name,
       eg.group_id
     FROM transactions t
     LEFT JOIN equb_groups eg ON eg.group_id = t.group_id
     WHERE t.transaction_id = $1 AND t.user_id = $2`,
    [id, req.userId]
  );

  if (rows.length === 0) {
    throw new AppError('Transaction not found', 404);
  }

  res.status(200).json({
    status: 'success',
    data: { transaction: rows[0] },
  });
});

// GET /api/v1/transactions/stats
// Returns summary statistics: total top-ups, total debits, total payouts received
export const getTransactionStats = asyncWrapper(async (req, res) => {
  const { rows } = await pool.query(
    `SELECT
       type,
       COUNT(*)::int AS count,
       SUM(amount) AS total_amount
     FROM transactions
     WHERE user_id = $1 AND status = 'completed'
     GROUP BY type`,
    [req.userId]
  );

  const stats = {
    top_up: { count: 0, total_amount: 0 },
    contribution_debit: { count: 0, total_amount: 0 },
    payout_credit: { count: 0, total_amount: 0 },
    adjustment: { count: 0, total_amount: 0 },
  };

  for (const row of rows) {
    stats[row.type] = {
      count: row.count,
      total_amount: Number(row.total_amount),
    };
  }

  const { rows: walletRows } = await pool.query(
    `SELECT wallet_balance FROM users WHERE user_id = $1`,
    [req.userId]
  );

  res.status(200).json({
    status: 'success',
    data: {
      wallet_balance: walletRows.length > 0 ? Number(walletRows[0].wallet_balance) : 0,
      stats,
    },
  });
});

// GET /api/v1/transactions/group/:groupId
// Returns transactions for a specific group (must be a member)
export const getGroupTransactions = asyncWrapper(async (req, res) => {
  const { groupId } = req.params;
  const { page = '1', limit = '20' } = req.query;

  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 20));
  const offset = (pageNum - 1) * limitNum;

  // Verify user is a member of the group
  const { rows: memberRows } = await pool.query(
    `SELECT member_id FROM group_members
     WHERE user_id = $1 AND group_id = $2 AND status = 'active'`,
    [req.userId, groupId]
  );

  if (memberRows.length === 0) {
    throw new AppError('You are not a member of this group', 403);
  }

  const [txResult, countResult] = await Promise.all([
    pool.query(
      `SELECT
         t.transaction_id,
         t.user_id,
         u.full_name,
         t.type,
         t.amount,
         t.status,
         t.created_at
       FROM transactions t
       JOIN users u ON u.user_id = t.user_id
       WHERE t.group_id = $1
       ORDER BY t.created_at DESC
       LIMIT $2 OFFSET $3`,
      [groupId, limitNum, offset]
    ),
    pool.query(
      `SELECT COUNT(*) AS total FROM transactions WHERE group_id = $1`,
      [groupId]
    ),
  ]);

  const total = parseInt(countResult.rows[0].total, 10);

  res.status(200).json({
    status: 'success',
    data: {
      transactions: txResult.rows,
      pagination: {
        total,
        page: pageNum,
        limit: limitNum,
        total_pages: Math.ceil(total / limitNum),
      },
    },
  });
});
