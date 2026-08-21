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
    'wallet_balance': 0.0,
    'active_groups_count': 0,
    'next_due_contribution': null,
    'recent_transactions': [],
  };
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _service.getDashboard();
      if (mounted) {
        setState(() {
          _data = res;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to connect to server';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final balanceVal = _data['wallet_balance'] ?? 0;
    final balance = (balanceVal is num ? balanceVal.toDouble() : double.tryParse('$balanceVal') ?? 0.0);
    final activeGroupsCount = _data['active_groups_count'] ?? 0;
    final nextDue = _data['next_due_contribution'];
    final recentTx = List<Map<String, dynamic>>.from(_data['recent_transactions'] ?? []);

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
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.error, fontSize: 13),
                          ),
                        ),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Retry', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: AppTheme.error)),
                        )
                      ],
                    ),
                  ),
                _BalanceCard(balance: balance),
                const SizedBox(height: 20),
                _QuickActions(context: context),
                const SizedBox(height: 20),
                _ActiveGroupsBadge(count: activeGroupsCount),
                const SizedBox(height: 20),
                if (nextDue != null) ...[
                  _NextPaymentCard(contribution: nextDue),
                  const SizedBox(height: 20),
                ],
                _RecentTransactions(transactions: recentTx),
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Balance', style: TextStyle(color: Colors.white70, fontFamily: 'Poppins', fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text('Secured Wallet', style: TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Poppins')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'ETB ${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/wallet/top-up'),
                  icon: const Icon(Icons.add_rounded, color: AppTheme.primary, size: 18),
                  label: const Text('Top Up', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/wallet'),
                  icon: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 18),
                  label: const Text('My Wallet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white70, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
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
      {'icon': Icons.account_balance_wallet_rounded, 'label': 'Wallet', 'route': '/wallet', 'color': AppTheme.primary},
      {'icon': Icons.payment_rounded, 'label': 'Pay', 'route': '/contributions', 'color': AppTheme.secondary},
      {'icon': Icons.savings_rounded, 'label': 'Payouts', 'route': '/payouts/schedule', 'color': const Color(0xFF7C3AED)},
      {'icon': Icons.bar_chart_rounded, 'label': 'Reports', 'route': '/reports', 'color': AppTheme.success},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: actions.map((a) {
          final color = a['color'] as Color;
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, a['route'] as String),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(a['icon'] as IconData, color: color, size: 26),
                ),
                const SizedBox(height: 8),
                Text(
                  a['label'] as String,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.darkText),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ActiveGroupsBadge extends StatelessWidget {
  final int count;
  const _ActiveGroupsBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/groups'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.groups_rounded, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count Active ${count == 1 ? 'Group' : 'Groups'}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tap to view and manage your Equb circles',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: AppTheme.grayText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppTheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextPaymentCard extends StatelessWidget {
  final Map<String, dynamic> contribution;
  const _NextPaymentCard({required this.contribution});

  @override
  Widget build(BuildContext context) {
    final amount = contribution['amount'];
    final formattedAmount = (amount is num ? amount.toDouble() : double.tryParse('$amount') ?? 0.0).toStringAsFixed(0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.upcoming_rounded, color: AppTheme.primary, size: 18),
                  SizedBox(width: 6),
                  Text('Next Due Payment', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkText)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Due ${contribution['due_date'] ?? 'Soon'}', style: const TextStyle(color: AppTheme.primary, fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contribution['group_name'] ?? 'Equb Group', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.darkText)),
                  Text('Cycle ${contribution['cycle_number'] ?? 1}', style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 12)),
                ],
              ),
              Text('ETB $formattedAmount', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/contributions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Review & Pay Now', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13)),
            ),
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
            const Text('Recent Activity', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.darkText)),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/transactions'),
              child: const Text('View All', style: TextStyle(fontFamily: 'Poppins', color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (transactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: const Center(
              child: Text('No recent activity recorded yet.', style: TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 13)),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 64, endIndent: 16),
              itemBuilder: (context, i) {
                final tx = transactions[i];
                final isCredit = tx['type'] == 'payout_credit' || tx['type'] == 'top_up';
                final Color color = isCredit ? AppTheme.success : AppTheme.error;
                final amount = tx['amount'];
                final formattedAmount = (amount is num ? amount.toDouble() : double.tryParse('$amount') ?? 0.0).toStringAsFixed(2);

                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      color: color,
                      size: 20,
                    ),
                  ),
                  title: Text(tx['group_name'] ?? _label(tx['type'] ?? ''), style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text(_label(tx['type'] ?? ''), style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 11)),
                  trailing: Text(
                    '${isCredit ? '+' : '-'}ETB $formattedAmount',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13, color: color),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  String _label(String type) {
    switch (type) {
      case 'top_up':
        return 'Wallet Top-Up';
      case 'contribution_debit':
        return 'Contribution Payment';
      case 'payout_credit':
        return 'Payout Received';
      default:
        return 'Transaction';
    }
  }
}
