import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../../data/wallet_service.dart';

class TransactionDetailPage extends StatefulWidget {
  final String transactionId;
  const TransactionDetailPage({super.key, required this.transactionId});

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  final _service = WalletService();
  Map<String, dynamic>? _tx;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _service.getTransactionById(widget.transactionId);
      if (mounted) setState(() { _tx = data['transaction']; _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); ErrorSnackbar.show(context, 'Failed to load transaction'); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = _tx?['type'] == 'payout_credit' || _tx?['type'] == 'top_up';
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Transaction Detail', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _loading,
        child: _tx == null ? const SizedBox() : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: isCredit ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: isCredit ? AppTheme.success : AppTheme.error,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${isCredit ? '+' : '-'}ETB ${_tx!['amount']}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        color: isCredit ? AppTheme.success : AppTheme.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_txLabel(_tx!['type'] ?? ''), style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 14)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(_tx!['status'] ?? '', style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.success, fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _DetailSection(items: [
                if (_tx!['group_name'] != null) _DetailItem('Group', _tx!['group_name']),
                _DetailItem('Type', _txLabel(_tx!['type'] ?? '')),
                _DetailItem('Reference', _tx!['reference_number'] ?? 'N/A'),
                _DetailItem('Date', _formatDate(_tx!['created_at'])),
                _DetailItem('Transaction ID', _tx!['transaction_id'] ?? ''),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  String _txLabel(String type) {
    switch (type) {
      case 'top_up': return 'Wallet Top-Up';
      case 'contribution_debit': return 'Contribution Paid';
      case 'payout_credit': return 'Payout Received';
      default: return 'Adjustment';
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final d = DateTime.parse(date.toString());
      return '${d.day}/${d.month}/${d.year}  ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) { return date.toString(); }
  }
}

class _DetailSection extends StatelessWidget {
  final List<_DetailItem> items;
  const _DetailSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.label, style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 13)),
              Flexible(
                child: Text(item.value, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppTheme.darkText, fontSize: 13), textAlign: TextAlign.right),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

class _DetailItem {
  final String label;
  final String value;
  const _DetailItem(this.label, this.value);
}

