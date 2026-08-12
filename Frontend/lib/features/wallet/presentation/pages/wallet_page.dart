import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../data/wallet_service.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final _service = WalletService();
  Map<String, dynamic> _wallet = {
    'wallet_balance': 12500.0,
    'full_name': 'Equb User',
  };
  Map<String, dynamic> _stats = {
    'stats': {
      'top_up': {'total_amount': 15000.0},
      'contribution_debit': {'total_amount': 4500.0},
      'payout_credit': {'total_amount': 12000.0},
    }
  };
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _service.getWallet(),
        _service.getTransactionStats(),
      ]);
      if (mounted && results[0].isNotEmpty) {
        setState(() {
          _wallet = results[0];
          _stats = results[1];
          _loading = false;
        });
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
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Wallet Balance', style: TextStyle(color: Colors.white70, fontFamily: 'Poppins', fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: const Text('Active', style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ETB ${(wallet['wallet_balance'] ?? 0).toDouble().toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 4),
          Text(wallet['full_name'] ?? '', style: const TextStyle(color: Colors.white60, fontSize: 13, fontFamily: 'Poppins')),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTopUp,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Top Up Wallet', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    return Row(
      children: [
        Expanded(child: _StatCard(
          label: 'Top-Ups',
          amount: ((s['top_up']?['total_amount']) ?? 0).toDouble(),
          color: AppTheme.secondary,
          icon: Icons.arrow_downward_rounded,
        )),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
          label: 'Paid Out',
          amount: ((s['contribution_debit']?['total_amount']) ?? 0).toDouble(),
          color: AppTheme.error,
          icon: Icons.arrow_upward_rounded,
        )),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(
          label: 'Received',
          amount: ((s['payout_credit']?['total_amount']) ?? 0).toDouble(),
          color: AppTheme.primary,
          icon: Icons.star_rounded,
        )),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text('ETB ${amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: color, fontSize: 13)),
          Text(label, style: const TextStyle(color: AppTheme.grayText, fontSize: 11, fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}

class _TransactionHistoryButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.pushNamed(context, '/transactions'),
        icon: const Icon(Icons.history_rounded),
        label: const Text('View All Transactions', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primary,
          side: const BorderSide(color: AppTheme.primary),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
