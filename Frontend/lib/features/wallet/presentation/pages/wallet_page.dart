import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../../data/wallet_service.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final _service = WalletService();
  Map<String, dynamic> _wallet = {
    'wallet_balance': 0.0,
    'full_name': '',
  };
  Map<String, dynamic> _stats = {
    'stats': {
      'top_up': {'total_amount': 0.0, 'count': 0},
      'contribution_debit': {'total_amount': 0.0, 'count': 0},
      'payout_credit': {'total_amount': 0.0, 'count': 0},
    }
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
      final results = await Future.wait([
        _service.getWallet(),
        _service.getTransactionStats(),
      ]);
      if (mounted) {
        setState(() {
          _wallet = results[0];
          _stats = results[1];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load wallet data';
        });
        ErrorSnackbar.show(context, 'Unable to fetch wallet balance from server');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Wallet', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
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
                _WalletCard(wallet: _wallet, onTopUp: _openTopUp),
                const SizedBox(height: 20),
                _StatsRow(stats: _stats),
                const SizedBox(height: 20),
                _TransactionHistoryButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openTopUp() async {
    final result = await Navigator.pushNamed(context, '/wallet/top-up');
    if (result == true) _load();
  }
}

class _WalletCard extends StatelessWidget {
  final Map<String, dynamic> wallet;
  final VoidCallback onTopUp;
  const _WalletCard({required this.wallet, required this.onTopUp});

  @override
  Widget build(BuildContext context) {
    final balance = (wallet['wallet_balance'] ?? 0);
    final formattedBalance = (balance is num ? balance.toDouble() : double.tryParse('$balance') ?? 0.0).toStringAsFixed(2);
    final userName = wallet['full_name'] ?? 'Equb Account';

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
              Text(
                userName.isNotEmpty ? userName : 'Equb Account',
                style: const TextStyle(color: Colors.white70, fontFamily: 'Poppins', fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Live Balance', style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'ETB $formattedBalance',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTopUp,
              icon: const Icon(Icons.add_rounded, color: AppTheme.primary, size: 20),
              label: const Text(
                'Top Up Wallet',
                style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final s = stats['stats'] as Map<String, dynamic>? ?? {};
    final topUp = (s['top_up']?['total_amount'] ?? 0);
    final debited = (s['contribution_debit']?['total_amount'] ?? 0);
    final payout = (s['payout_credit']?['total_amount'] ?? 0);

    final topUpVal = (topUp is num ? topUp.toDouble() : double.tryParse('$topUp') ?? 0.0);
    final debitedVal = (debited is num ? debited.toDouble() : double.tryParse('$debited') ?? 0.0);
    final payoutVal = (payout is num ? payout.toDouble() : double.tryParse('$payout') ?? 0.0);

    return Row(
      children: [
        _StatCard(label: 'Total Top-Up', amount: topUpVal, color: AppTheme.success, icon: Icons.arrow_downward_rounded),
        const SizedBox(width: 10),
        _StatCard(label: 'Contributed', amount: debitedVal, color: AppTheme.error, icon: Icons.arrow_upward_rounded),
        const SizedBox(width: 10),
        _StatCard(label: 'Payouts', amount: payoutVal, color: AppTheme.secondary, icon: Icons.monetization_on_rounded),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  const _StatCard({required this.label, required this.amount, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(
              'ETB ${amount.toStringAsFixed(0)}',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _TransactionHistoryButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primary, size: 20),
        ),
        title: const Text('Transaction History', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: const Text('View all deposits, payouts & payments', style: TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 11)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.grayText),
        onTap: () => Navigator.pushNamed(context, '/transactions'),
      ),
    );
  }
}
