import { pool } from '../db/pool.js';
import { AppError } from '../utils/AppError.js';
import { asyncWrapper } from '../utils/asyncWrapper.js';

async function writeAuditLog(client, userId, action, entityName, entityId) {
  await client.query(
    `INSERT INTO audit_logs (user_id, action, entity_name, entity_id)
     VALUES ($1, $2, $3, $4)`,
    [userId, action, entityName, entityId]
  );
}

// Get user dashboard data summary
export const getDashboard = asyncWrapper(async (req, res) => {
  const userId = req.userId;

  const [walletRes, groupsRes, nextDueRes, txRes] = await Promise.all([
    pool.query(
      `SELECT wallet_balance FROM users WHERE user_id = $1 AND is_deleted = FALSE`,
      [userId]
    ),
    pool.query(
      `SELECT COUNT(*)::int AS count
       FROM group_members gm
       JOIN equb_groups eg ON eg.group_id = gm.group_id
       WHERE gm.user_id = $1 AND gm.status = 'active' AND eg.status = 'active'`,
      [userId]
    ),
    pool.query(
      `SELECT
         c.contribution_id,
         c.group_id,
         eg.group_name,
         c.cycle_number,
         c.amount,
         c.due_date,
         c.status
       FROM contributions c
       JOIN group_members gm ON gm.member_id = c.member_id
       JOIN equb_groups eg ON eg.group_id = c.group_id
       WHERE gm.user_id = $1 AND c.status IN ('pending', 'overdue')
       ORDER BY c.due_date ASC
       LIMIT 1`,
      [userId]
    ),
    pool.query(
      `SELECT
         t.transaction_id,
         t.type,
         t.amount,
         t.status,
         t.created_at,
         eg.group_name
       FROM transactions t
       LEFT JOIN equb_groups eg ON eg.group_id = t.group_id
       WHERE t.user_id = $1
       ORDER BY t.created_at DESC
       LIMIT 3`,
      [userId]
    ),
  ]);

  if (walletRes.rows.length === 0) {
    throw new AppError('User not found', 404);
  }

  res.status(200).json({
    status: 'success',
    data: {
      wallet_balance: Number(walletRes.rows[0].wallet_balance),
      active_groups_count: groupsRes.rows[0].count,
      next_due_contribution: nextDueRes.rows[0] || null,
      recent_transactions: txRes.rows,
    },
  });
});

// Get user financial summary
export const getUserSummary = asyncWrapper(async (req, res) => {
  const userId = req.userId;

  const [walletRes, contribRes, payoutRes, groupsRes] = await Promise.all([
    pool.query(`SELECT wallet_balance FROM users WHERE user_id = $1`, [userId]),
    pool.query(
      `SELECT
         COALESCE(SUM(c.amount), 0) AS total_contributed,
         COUNT(c.contribution_id)::int AS total_contributions_paid
       FROM contributions c
       JOIN group_members gm ON gm.member_id = c.member_id
       WHERE gm.user_id = $1 AND c.status = 'paid'`,
      [userId]
    ),
    pool.query(
      `SELECT
         COALESCE(SUM(p.payout_amount), 0) AS total_received,
         COUNT(p.payout_id)::int AS total_payouts_count
       FROM payouts p
       JOIN group_members gm ON gm.member_id = p.member_id
       WHERE gm.user_id = $1 AND p.status = 'completed'`,
      [userId]
    ),
    pool.query(
      `SELECT
         COUNT(gm.member_id)::int AS total_groups_joined,
         COUNT(CASE WHEN eg.status = 'active' THEN 1 END)::int AS active_groups,
         COUNT(CASE WHEN eg.status = 'completed' THEN 1 END)::int AS completed_groups
       FROM group_members gm
       JOIN equb_groups eg ON eg.group_id = gm.group_id
       WHERE gm.user_id = $1 AND gm.status = 'active'`,
      [userId]
    ),
  ]);

  res.status(200).json({
    status: 'success',
    data: {
      wallet_balance: Number(walletRes.rows[0]?.wallet_balance || 0),
      total_contributed: Number(contribRes.rows[0].total_contributed),
      total_contributions_paid: contribRes.rows[0].total_contributions_paid,
      total_payouts_received: Number(payoutRes.rows[0].total_received),
      total_payouts_count: payoutRes.rows[0].total_payouts_count,
      group_stats: groupsRes.rows[0],
    },
  });
});

// Get group financial summary report
export const getGroupSummary = asyncWrapper(async (req, res) => {
  const groupId = req.query.group_id || req.params.groupId;

  if (!groupId) {
    throw new AppError('group_id parameter is required', 400);
  }

  if (req.userRole !== 'system_admin') {
    const { rows: memberCheck } = await pool.query(
      `SELECT member_id FROM group_members
       WHERE user_id = $1 AND group_id = $2 AND status = 'active'`,
      [req.userId, groupId]
    );
    if (memberCheck.length === 0) {
      throw new AppError('You are not a member of this group', 403);
    }
  }

  const [groupRes, contribRes, payoutRes, memberRes] = await Promise.all([
    pool.query(
      `SELECT group_id, group_name, contribution_amount, cycle_duration, max_members, current_cycle, status
       FROM equb_groups WHERE group_id = $1 AND is_deleted = FALSE`,
      [groupId]
    ),
    pool.query(
      `SELECT
         COALESCE(SUM(CASE WHEN status = 'paid' THEN amount ELSE 0 END), 0) AS total_collected,
         COUNT(CASE WHEN status = 'paid' THEN 1 END)::int AS paid_count,
         COUNT(CASE WHEN status = 'pending' THEN 1 END)::int AS pending_count,
         COUNT(CASE WHEN status = 'overdue' THEN 1 END)::int AS overdue_count
       FROM contributions WHERE group_id = $1`,
      [groupId]
    ),
    pool.query(
      `SELECT
         COALESCE(SUM(CASE WHEN status = 'completed' THEN payout_amount ELSE 0 END), 0) AS total_paid_out,
         COUNT(CASE WHEN status = 'completed' THEN 1 END)::int AS completed_payouts_count
       FROM payouts WHERE group_id = $1`,
      [groupId]
    ),
    pool.query(
      `SELECT
         gm.member_id,
         u.full_name,
         gm.position_in_cycle,
         gm.role,
         gm.status AS member_status
       FROM group_members gm
       JOIN users u ON u.user_id = gm.user_id
       WHERE gm.group_id = $1
       ORDER BY gm.position_in_cycle ASC`,
      [groupId]
    ),
  ]);

  if (groupRes.rows.length === 0) {
    throw new AppError('Group not found', 404);
  }

  const group = groupRes.rows[0];
  const maxMembers = group.max_members || 1;
  const currentCycle = group.current_cycle || 1;
  const remainingCycles = Math.max(0, maxMembers - currentCycle + 1);
  const completionPercentage = group.status === 'completed'
    ? 100
    : Math.min(100, Math.round(((currentCycle - 1) / maxMembers) * 100));

  res.status(200).json({
    status: 'success',
    data: {
      group: {
        group_id: group.group_id,
        group_name: group.group_name,
        contribution_amount: Number(group.contribution_amount),
        cycle_duration: group.cycle_duration,
        max_members: group.max_members,
        current_cycle: group.current_cycle,
        status: group.status,
        remaining_cycles: remainingCycles,
        completion_percentage: completionPercentage,
      },
      financials: {
        total_collected: Number(contribRes.rows[0].total_collected),
        total_paid_out: Number(payoutRes.rows[0].total_paid_out),
        paid_contributions_count: contribRes.rows[0].paid_count,
        pending_contributions_count: contribRes.rows[0].pending_count,
        overdue_contributions_count: contribRes.rows[0].overdue_count,
      },
      members: memberRes.rows,
    },
  });
});

// Get user contributions statistics report
export const getContributionsReport = asyncWrapper(async (req, res) => {
  const userId = req.userId;

  const { rows } = await pool.query(
    `SELECT
       c.status,
       COUNT(*)::int AS count,
       COALESCE(SUM(c.amount), 0) AS total_amount
     FROM contributions c
     JOIN group_members gm ON gm.member_id = c.member_id
     WHERE gm.user_id = $1
     GROUP BY c.status`,
    [userId]
  );

  const breakdown = {
    paid: { count: 0, total_amount: 0 },
    pending: { count: 0, total_amount: 0 },
    overdue: { count: 0, total_amount: 0 },
  };

  let totalCount = 0;
  let paidCount = 0;

  for (const r of rows) {
    breakdown[r.status] = {
      count: r.count,
      total_amount: Number(r.total_amount),
    };
    totalCount += r.count;
    if (r.status === 'paid') paidCount = r.count;
  }

  const onTimePercentage = totalCount > 0 ? Math.round((paidCount / totalCount) * 100) : 0;

  res.status(200).json({
    status: 'success',
    data: {
      breakdown,
      total_contributions: totalCount,
      on_time_percentage: onTimePercentage,
    },
  });
});

// Get user payouts statistics report
export const getPayoutsReport = asyncWrapper(async (req, res) => {
  const userId = req.userId;

  const { rows } = await pool.query(
    `SELECT
       p.status,
       COUNT(*)::int AS count,
       COALESCE(SUM(p.payout_amount), 0) AS total_amount
     FROM payouts p
     JOIN group_members gm ON gm.member_id = p.member_id
     WHERE gm.user_id = $1
     GROUP BY p.status`,
    [userId]
  );

  const breakdown = {
    completed: { count: 0, total_amount: 0 },
    pending: { count: 0, total_amount: 0 },
    rejected: { count: 0, total_amount: 0 },
  };

  for (const r of rows) {
    breakdown[r.status] = {
      count: r.count,
      total_amount: Number(r.total_amount),
    };
  }

  res.status(200).json({
    status: 'success',
    data: { breakdown },
  });
});

// Get combined financial overview
export const getFinancialOverview = asyncWrapper(async (req, res) => {
  const userId = req.userId;

  const [walletRes, txRes] = await Promise.all([
    pool.query(`SELECT wallet_balance FROM users WHERE user_id = $1`, [userId]),
    pool.query(
      `SELECT
         type,
         COUNT(*)::int AS count,
         COALESCE(SUM(amount), 0) AS total_amount
       FROM transactions
       WHERE user_id = $1 AND status = 'completed'
       GROUP BY type`,
      [userId]
    ),
  ]);

  const summary = {
    top_up: { count: 0, total_amount: 0 },
    contribution_debit: { count: 0, total_amount: 0 },
    payout_credit: { count: 0, total_amount: 0 },
    adjustment: { count: 0, total_amount: 0 },
  };

  for (const r of txRes.rows) {
    summary[r.type] = {
      count: r.count,
      total_amount: Number(r.total_amount),
    };
  }

  const currentBalance = Number(walletRes.rows[0]?.wallet_balance || 0);

  res.status(200).json({
    status: 'success',
    data: {
      wallet_balance: currentBalance,
      transactions_summary: summary,
    },
  });
});

// Get monthly contributions analytics for past 12 months
export const getAnalytics = asyncWrapper(async (req, res) => {
  const userId = req.userId;

  const { rows } = await pool.query(
    `SELECT
       TO_CHAR(c.paid_date, 'YYYY-MM') AS month,
       COUNT(*)::int AS count,
       COALESCE(SUM(c.amount), 0) AS total_amount
     FROM contributions c
     JOIN group_members gm ON gm.member_id = c.member_id
     WHERE gm.user_id = $1
       AND c.status = 'paid'
       AND c.paid_date >= NOW() - INTERVAL '12 months'
     GROUP BY TO_CHAR(c.paid_date, 'YYYY-MM')
     ORDER BY month ASC`,
    [userId]
  );

  const formattedRows = rows.map((r) => ({
    month: r.month,
    count: r.count,
    total_amount: Number(r.total_amount),
  }));

  res.status(200).json({
    status: 'success',
    data: {
      monthly_contributions: formattedRows,
    },
  });
});

// Generate and stream PDF report as a downloadable file
export const exportPdf = asyncWrapper(async (req, res) => {
  const userId = req.userId;

  const { rows: txRows } = await pool.query(
    `SELECT t.transaction_id, t.type, t.amount, t.status, t.created_at
     FROM transactions t
     WHERE t.user_id = $1
     ORDER BY t.created_at DESC
     LIMIT 100`,
    [userId]
  );

  const { rows: userRows } = await pool.query(
    `SELECT full_name, phone_number, wallet_balance FROM users WHERE user_id = $1`,
    [userId]
  );

  const user = userRows[0] || {};
  const now = new Date().toISOString();

  let content = `EQUB PLATFORM - FINANCIAL REPORT\n`;
  content += `Generated: ${now}\n`;
  content += `Account: ${user.full_name || 'N/A'} | ${user.phone_number || ''}\n`;
  content += `Wallet Balance: ETB ${Number(user.wallet_balance || 0).toFixed(2)}\n`;
  content += `${'='.repeat(60)}\n\n`;
  content += `TRANSACTION HISTORY (Last 100)\n`;
  content += `${'='.repeat(60)}\n`;
  content += `${'Date'.padEnd(25)}${'Type'.padEnd(16)}${'Amount'.padEnd(14)}Status\n`;
  content += `${'-'.repeat(60)}\n`;

  for (const r of txRows) {
    const date = new Date(r.created_at).toLocaleString();
    const type = (r.type || '').padEnd(15);
    const amount = `ETB ${Number(r.amount).toFixed(2)}`.padEnd(13);
    const status = r.status || '';
    content += `${date.padEnd(25)}${type} ${amount} ${status}\n`;
  }

  content += `\n${'='.repeat(60)}\n`;
  content += `Total transactions: ${txRows.length}\n`;

  await writeAuditLog(pool, userId, 'export_generated', 'reports', userId);

  res.setHeader('Content-Type', 'text/plain; charset=utf-8');
  res.setHeader('Content-Disposition', 'attachment; filename="equb_financial_report.txt"');
  res.status(200).send(content);
});

// Export financial transactions report as CSV
export const exportExcel = asyncWrapper(async (req, res) => {
  const userId = req.userId;

  const { rows } = await pool.query(
    `SELECT
       t.transaction_id,
       t.type,
       t.amount,
       t.status,
       t.created_at
     FROM transactions t
     WHERE t.user_id = $1
     ORDER BY t.created_at DESC`,
    [userId]
  );

  let csvContent = 'Transaction ID,Type,Amount,Status,Date\n';
  for (const r of rows) {
    csvContent += `"${r.transaction_id}","${r.type}",${r.amount},"${r.status}","${r.created_at.toISOString()}"\n`;
  }

  await writeAuditLog(pool, userId, 'export_generated', 'reports', userId);

  res.setHeader('Content-Type', 'text/csv');
  res.setHeader('Content-Disposition', 'attachment; filename="financial_report.csv"');
  res.status(200).send(csvContent);
});

async function assertGroupMember(userId, groupId) {
  const { rows } = await pool.query(
    `SELECT 1 FROM group_members
     WHERE user_id = $1 AND group_id = $2 AND status = 'active'`,
    [userId, groupId]
  );
  if (rows.length === 0) throw new AppError('You are not a member of this group', 403);
}

export const exportGroupPdf = asyncWrapper(async (req, res) => {
  const { group_id: groupId } = req.query;
  if (!groupId) throw new AppError('group_id parameter is required', 400);
  await assertGroupMember(req.userId, groupId);

  const { rows } = await pool.query(
    `SELECT t.created_at, t.type, t.amount, t.status, u.full_name
     FROM transactions t
     JOIN users u ON u.user_id = t.user_id
     WHERE t.group_id = $1
     ORDER BY t.created_at DESC`,
    [groupId]
  );
  const { rows: groupRows } = await pool.query(
    `SELECT group_name FROM equb_groups WHERE group_id = $1`,
    [groupId]
  );
  let content = `EQUB GROUP REPORT - ${groupRows[0]?.group_name || groupId}\n`;
  content += `Generated: ${new Date().toISOString()}\n\n`;
  content += `Date\tMember\tType\tAmount\tStatus\n`;
  for (const row of rows) {
    content += `${new Date(row.created_at).toISOString()}\t${row.full_name}\t${row.type}\tETB ${Number(row.amount).toFixed(2)}\t${row.status}\n`;
  }
  res.setHeader('Content-Type', 'text/plain; charset=utf-8');
  res.setHeader('Content-Disposition', 'attachment; filename="equb_group_report.txt"');
  res.status(200).send(content);
});

export const exportGroupExcel = asyncWrapper(async (req, res) => {
  const { group_id: groupId } = req.query;
  if (!groupId) throw new AppError('group_id parameter is required', 400);
  await assertGroupMember(req.userId, groupId);
  const { rows } = await pool.query(
    `SELECT t.transaction_id, u.full_name, t.type, t.amount, t.status, t.created_at
     FROM transactions t
     JOIN users u ON u.user_id = t.user_id
     WHERE t.group_id = $1 ORDER BY t.created_at DESC`,
    [groupId]
  );
  let csvContent = 'Transaction ID,Member,Type,Amount,Status,Date\n';
  for (const row of rows) {
    csvContent += `"${row.transaction_id}","${row.full_name}","${row.type}",${row.amount},"${row.status}","${row.created_at.toISOString()}"\n`;
  }
  res.setHeader('Content-Type', 'text/csv');
  res.setHeader('Content-Disposition', 'attachment; filename="equb_group_report.csv"');
  res.status(200).send(csvContent);
});
