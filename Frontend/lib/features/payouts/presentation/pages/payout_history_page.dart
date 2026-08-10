import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../data/payouts_service.dart';

class PayoutHistoryPage extends StatefulWidget {
  const PayoutHistoryPage({super.key});

  @override
  State<PayoutHistoryPage> createState() => _PayoutHistoryPageState();
}

class _PayoutHistoryPageState extends State<PayoutHistoryPage> {
  final _service = PayoutsService();
  List<Map<String, dynamic>> _payouts = [
    {
      'payout_id': 'po-101',
      'group_name': 'Monthly Executive Equb',
      'cycle_number': 1,
      'payout_amount': 12000.0,
      'payout_date': '2026-08-05T09:00:00Z',
      'status': 'completed',
    },
  ];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _service.getHistory();
      final list = List<Map<String, dynamic>>.from(data['payouts'] ?? []);
      if (mounted && list.isNotEmpty) {
        setState(() { _payouts = list; _loading = false; });
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
        title: const Text('Payout History', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _loading,
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () => _load(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _payouts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              return _PayoutCard(payout: _payouts[i], onTap: () => Navigator.pushNamed(context, '/payouts/${_payouts[i]['payout_id']}'));
            },
          ),
        ),
      ),
    );
  }
}

class _PayoutCard extends StatelessWidget {
  final Map<String, dynamic> payout;
  final VoidCallback onTap;
  const _PayoutCard({required this.payout, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.monetization_on_rounded, color: AppTheme.success, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(payout['group_name'] ?? 'Equb Group', style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: AppTheme.darkText, fontSize: 14)),
                  Text('Cycle ${payout['cycle_number'] ?? 1}  •  ${_formatDate(payout['payout_date'])}', style: const TextStyle(color: AppTheme.grayText, fontSize: 12, fontFamily: 'Poppins')),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('+ETB ${payout['payout_amount'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: AppTheme.success, fontSize: 15)),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('completed', style: TextStyle(color: AppTheme.success, fontSize: 10, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
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
