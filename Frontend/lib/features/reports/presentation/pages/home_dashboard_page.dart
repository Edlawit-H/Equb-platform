import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../reports/data/reports_service.dart';

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  final _service = ReportsService();
  Map<String, dynamic> _data = {
    'wallet_balance': 12500.0,
    'active_groups_count': 3,
    'next_due_contribution': {
      'group_name': 'Weekly Savings Equb',
      'due_date': '2026-08-15',
      'amount': 1000.0,
    },
    'recent_transactions': [
      {'type': 'top_up', 'amount': 5000, 'group_name': 'Wallet Top-Up'},
      {'type': 'contribution_debit', 'amount': 1000, 'group_name': 'Weekly Savings Equb'},
      {'type': 'payout_credit', 'amount': 12000, 'group_name': 'Monthly Executive Equb'},
    ],
  };
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _service.getDashboard();
      if (mounted && res.isNotEmpty) {
        setState(() { _data = res; _loading = false; });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Equb Dashboard', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: AppTheme.darkText),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _loading,
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BalanceCard(balance: (_data['wallet_balance'] ?? 0).toDouble()),
                const SizedBox(height: 20),
                _QuickActions(context: context),
                const SizedBox(height: 20),
                _ActiveGroupsBadge(count: _data['active_groups_count'] ?? 0),
                const SizedBox(height: 20),
                if (_data['next_due_contribution'] != null)
                  _NextPaymentCard(contribution: _data['next_due_contribution']),
                const SizedBox(height: 20),
                _RecentTransactions(transactions: List<Map<String, dynamic>>.from(
                  _data['recent_transactions'] ?? [],
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFFEA580C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Poppins')),
          const SizedBox(height: 8),
          Text(
            'ETB ${balance.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 16),
          const Text('Online Equb Wallet', style: TextStyle(color: Colors.white60, fontSize: 12, fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final BuildContext context;
  const _QuickActions({required this.context});

  @override
  Widget build(BuildContext context) {
    final actions = [
      {'icon': Icons.account_balance_wallet_rounded, 'label': 'Wallet', 'route': '/wallet'},
      {'icon': Icons.payments_rounded, 'label': 'Pay', 'route': '/contributions'},
      {'icon': Icons.timeline_rounded, 'label': 'Payouts', 'route': '/payouts/schedule'},
      {'icon': Icons.bar_chart_rounded, 'label': 'Reports', 'route': '/reports'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((a) => _ActionItem(
        icon: a['icon'] as IconData,
        label: a['label'] as String,
        onTap: () => Navigator.pushNamed(context, a['route'] as String),
      )).toList(),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontFamily: 'Poppins', color: AppTheme.darkText, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ActiveGroupsBadge extends StatelessWidget {
  final int count;
  const _ActiveGroupsBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Active Equbs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: AppTheme.darkText)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count Active',
            style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w600, fontSize: 12, fontFamily: 'Poppins'),
          ),
        ),
      ],
    );
  }
}

class _NextPaymentCard extends StatelessWidget {
  final Map<String, dynamic> contribution;
  const _NextPaymentCard({required this.contribution});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.schedule_rounded, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contribution['group_name'] ?? 'Equb Group',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: AppTheme.darkText),
                ),
                const SizedBox(height: 2),
                Text(
                  'Due: ${contribution['due_date'] ?? '—'}',
                  style: const TextStyle(color: AppTheme.grayText, fontSize: 12, fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),
          Text(
            'ETB ${contribution['amount'] ?? 0}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontFamily: 'Poppins', fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  const _RecentTransactions({required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: AppTheme.darkText)),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/transactions'),
              child: const Text('See All', style: TextStyle(color: AppTheme.primary, fontFamily: 'Poppins')),
            ),
          ],
        ),
        if (transactions.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('No transactions yet', style: TextStyle(color: AppTheme.grayText, fontFamily: 'Poppins')),
          ))
        else
          ...transactions.map((tx) => _TransactionTile(tx: tx)),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isCredit = tx['type'] == 'payout_credit' || tx['type'] == 'top_up';
    final amount = tx['amount'] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCredit ? AppTheme.success.withOpacity(0.1) : AppTheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isCredit ? AppTheme.success : AppTheme.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _txLabel(tx['type'] ?? ''),
                  style: const TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Poppins', color: AppTheme.darkText, fontSize: 14),
                ),
                if (tx['group_name'] != null)
                  Text(tx['group_name'], style: const TextStyle(color: AppTheme.grayText, fontSize: 12, fontFamily: 'Poppins')),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}ETB $amount',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: isCredit ? AppTheme.success : AppTheme.error,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _txLabel(String type) {
    switch (type) {
      case 'top_up': return 'Wallet Top-Up';
      case 'contribution_debit': return 'Contribution Paid';
      case 'payout_credit': return 'Payout Received';
      default: return 'Transaction';
    }
  }
}
