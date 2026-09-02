import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../../data/wallet_service.dart';

class TopUpPage extends StatefulWidget {
  const TopUpPage({super.key});

  @override
  State<TopUpPage> createState() => _TopUpPageState();
}

class _TopUpPageState extends State<TopUpPage> {
  final _service = WalletService();
  final _amountController = TextEditingController();
  bool _loading = false;
  bool _success = false;
  String? _errorMsg;

  Future<void> _confirm() async {
    final raw = double.tryParse(_amountController.text.trim());
    if (raw == null || raw <= 0) {
      setState(() => _errorMsg = 'Enter a valid amount');
      return;
    }
    setState(() { _loading = true; _errorMsg = null; });
    try {
      await _service.topUp(raw);
      if (mounted) setState(() { _loading = false; _success = true; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ErrorSnackbar.show(context, 'Top-up failed. Please try again.');
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Top Up Wallet', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
      ),
      body: _success ? _SuccessView(onDone: () => Navigator.pop(context, true)) : _FormView(
        controller: _amountController,
        loading: _loading,
        errorMsg: _errorMsg,
        onConfirm: _confirm,
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final String? errorMsg;
  final VoidCallback onConfirm;
  const _FormView({required this.controller, required this.loading, this.errorMsg, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final quickAmounts = [100, 200, 500, 1000, 2000, 5000];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Funds will be added to your internal wallet and used for Equb contributions.',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppTheme.darkText),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text('Enter Amount (ETB)', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppTheme.darkText, fontSize: 15)),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: const TextStyle(color: AppTheme.grayText, fontFamily: 'Poppins'),
              prefixText: 'ETB  ',
              prefixStyle: const TextStyle(fontFamily: 'Poppins', color: AppTheme.darkText, fontSize: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
              errorText: errorMsg,
            ),
          ),
          const SizedBox(height: 20),
          const Text('Quick Select', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, color: AppTheme.grayText, fontSize: 13)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: quickAmounts.map((amt) => GestureDetector(
              onTap: () => controller.text = amt.toString(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
                child: Text('ETB $amt', style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: loading ? null : onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: loading
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Confirm Top-Up', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 56),
            ),
            const SizedBox(height: 24),
            const Text('Payment Successful!', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 22, color: AppTheme.darkText)),
            const SizedBox(height: 8),
            const Text('Your wallet has been topped up.', style: TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 14)),
            const SizedBox(height: 36),
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
                child: const Text('Back to Wallet', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

