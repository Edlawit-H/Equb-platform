import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../data/payouts_service.dart';

class PayoutSchedulePage extends StatefulWidget {
  const PayoutSchedulePage({super.key});

  @override
  State<PayoutSchedulePage> createState() => _PayoutSchedulePageState();
}

class _PayoutSchedulePageState extends State<PayoutSchedulePage> {
  final _service = PayoutsService();
  List<Map<String, dynamic>> _schedule = [];
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
      final data = await _service.getSchedule();
      final list = List<Map<String, dynamic>>.from(data['schedule'] ?? []);
      if (mounted) {
        setState(() {
          _schedule = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load payout schedule';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Payout Schedule', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
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
              : _schedule.isEmpty && !_loading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 52, color: AppTheme.grayText.withValues(alpha: 0.5)),
                          const SizedBox(height: 14),
                          const Text(
                            'No active payout schedules',
                            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppTheme.darkText, fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Join or create an Equb group to see your payout rotation timeline.',
                            style: TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _schedule.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _ScheduleCard(item: _schedule[i]),
                    ),
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ScheduleCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final status = item['status'] ?? 'upcoming';
    final Color statusColor = status == 'completed'
        ? AppTheme.success
        : status == 'current'
            ? AppTheme.primary
            : AppTheme.grayText;

    final IconData icon = status == 'completed'
        ? Icons.check_circle_rounded
        : status == 'current'
            ? Icons.star_rounded
            : Icons.radio_button_unchecked_rounded;

    final amount = item['estimated_payout_amount'];
    final formattedAmount = (amount is num ? amount.toDouble() : double.tryParse('$amount') ?? 0.0).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: status == 'current' ? Border.all(color: AppTheme.primary, width: 1.5) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['group_name'] ?? 'Equb Group',
                  style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.darkText),
                ),
                const SizedBox(height: 2),
                Text(
                  'Position ${item['position_in_cycle'] ?? '—'} • ${item['projected_date'] ?? 'Upcoming'}',
                  style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '~ETB $formattedAmount',
                style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkText),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toString().toUpperCase(),
                  style: TextStyle(fontFamily: 'Poppins', color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
