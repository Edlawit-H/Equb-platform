import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../../data/contributions_service.dart';

class PayContributionPage extends StatefulWidget {
  final Map<String, dynamic> contribution;
  const PayContributionPage({super.key, required this.contribution});

  @override
  State<PayContributionPage> createState() => _PayContributionPageState();
}

class _PayContributionPageState extends State<PayContributionPage> {
  final _service = ContributionsService();
  bool _loading = false;
  bool _success = false;
  bool _failed = false;
  String _errorMessage = '';

  Future<void> _pay() async {
    setState(() { _loading = true; _failed = false; });
    try {
      await _service.pay(
        widget.contribution['group_id'],
        widget.contribution['cycle_number'] as int,
      );
      if (mounted) setState(() { _loading = false; _success = true; });
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
          _errorMessage = msg.isNotEmpty ? msg : 'Payment failed. Please try again.';
        });
        ErrorSnackbar.show(context, _errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_success) return _SuccessView(onDone: () => Navigator.pop(context, true));
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Pay Contribution', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryCard(contribution: widget.contribution),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Payment will be deducted from your Equb wallet balance.',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppTheme.darkText),
                    ),
                  ),
                ],
              ),
            ),
            if (_failed)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 18),
                    SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage.isNotEmpty ? _errorMessage : 'Payment failed. Please ensure you have sufficient balance.', style: TextStyle(fontFamily: 'Poppins', color: AppTheme.error, fontSize: 12))),
                  ]),
                ),
              ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Confirm & Pay', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Map<String, dynamic> contribution;
  const _SummaryCard({required this.contribution});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Summary', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppTheme.darkText, fontSize: 15)),
          const Divider(height: 24),
          _Row('Group', contribution['group_name'] ?? 'â€”'),
          _Row('Cycle', 'Cycle ${contribution['cycle_number'] ?? 1}'),
          _Row('Due Date', contribution['due_date'] ?? 'â€”'),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Amount', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkText)),
              Text('ETB ${contribution['amount'] ?? 0}', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _Row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 13)),
          Text(value, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppTheme.darkText, fontSize: 13)),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final VoidCallback onDone;
  const _SuccessView({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 60),
              ),
              const SizedBox(height: 24),
              const Text('Payment Successful!', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 22, color: AppTheme.darkText)),
              const SizedBox(height: 8),
              const Text('Your contribution has been paid.', style: TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 14)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Back to Home', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

