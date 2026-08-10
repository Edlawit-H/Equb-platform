import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../../data/payouts_service.dart';

class PayoutDetailPage extends StatefulWidget {
  final String payoutId;
  const PayoutDetailPage({super.key, required this.payoutId});

  @override
  State<PayoutDetailPage> createState() => _PayoutDetailPageState();
}

class _PayoutDetailPageState extends State<PayoutDetailPage> {
  final _service = PayoutsService();
  Map<String, dynamic>? _payout;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _service.getById(widget.payoutId);
      if (mounted) setState(() { _payout = data['payout']; _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); ErrorSnackbar.show(context, 'Failed to load payout'); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _payout;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Payout Detail', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _loading,
        child: p == null ? const SizedBox() : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.monetization_on_rounded, color: AppTheme.success, size: 36),
                    ),
                    const SizedBox(height: 14),
                    Text('+ETB ${p['payout_amount'] ?? 0}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: AppTheme.success)),
                    const SizedBox(height: 4),
                    Text(p['group_name'] ?? '—', style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 14)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(p['status'] ?? '—', style: const TextStyle(color: AppTheme.success, fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _DetailCard(payout: p),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final Map<String, dynamic> payout;
  const _DetailCard({required this.payout});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          _Row('Recipient', payout['recipient_name'] ?? '—'),
          _Row('Group', payout['group_name'] ?? '—'),
          _Row('Cycle Number', 'Cycle ${payout['cycle_number'] ?? 1}'),
          _Row('Payout Date', _formatDate(payout['payout_date'])),
          _Row('Amount', 'ETB ${payout['payout_amount'] ?? 0}'),
          _Row('Status', payout['status'] ?? '—'),
        ],
      ),
    );
  }

  Widget _Row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 13)),
          Flexible(child: Text(value, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppTheme.darkText, fontSize: 13), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '—';
    try {
      final d = DateTime.parse(date.toString());
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) { return date.toString(); }
  }
}
