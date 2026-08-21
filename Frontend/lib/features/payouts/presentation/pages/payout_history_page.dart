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
  List<Map<String, dynamic>> _payouts = [];
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
      final data = await _service.getHistory();
      final list = List<Map<String, dynamic>>.from(data['payouts'] ?? []);
      if (mounted) {
        setState(() {
          _payouts = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load payout history';
        });
      }
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
          onRefresh: _load,
          child: _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 36),
                      const SizedBox(height: 10),
                      Text(_error!, style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.error, fontSize: 13)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _load,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                        child: const Text('Retry', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
                      ),
                    ],
                  ),
                )
              : _payouts.isEmpty && !_loading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.savings_rounded, size: 52, color: AppTheme.grayText.withValues(alpha: 0.5)),
                          const SizedBox(height: 14),
                          const Text(
                            'No completed payouts yet',
                            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppTheme.darkText, fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'When you win a cycle draw, your payout records will appear here.',
                            style: TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _payouts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        return _PayoutCard(
                          payout: _payouts[i],
                          onTap: () => Navigator.pushNamed(context, '/payouts/${_payouts[i]['payout_id']}'),
                        );
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
    final amount = payout['payout_amount'];
    final formattedAmount = (amount is num ? amount.toDouble() : double.tryParse('$amount') ?? 0.0).toStringAsFixed(2);
    final dateStr = (payout['payout_date'] ?? '').toString().split('T').first;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.monetization_on_rounded, color: AppTheme.success, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payout['group_name'] ?? 'Equb Payout',
                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.darkText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Cycle ${payout['cycle_number']} • ${dateStr.isNotEmpty ? dateStr : 'Completed'}',
                    style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+ETB $formattedAmount',
                  style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.success),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Received', style: TextStyle(fontFamily: 'Poppins', color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
