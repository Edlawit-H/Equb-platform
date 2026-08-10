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
  List<Map<String, dynamic>> _schedule = [
    {
      'payout_id': 'po-201',
      'group_name': 'Weekly Savings Equb',
      'position_in_cycle': 2,
      'projected_date': '2026-08-20',
      'estimated_payout_amount': 12000.0,
      'status': 'current',
    },
    {
      'payout_id': 'po-202',
      'group_name': 'Monthly Executive Equb',
      'position_in_cycle': 5,
      'projected_date': '2026-09-01',
      'estimated_payout_amount': 50000.0,
      'status': 'upcoming',
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
      final data = await _service.getSchedule();
      final list = List<Map<String, dynamic>>.from(data['schedule'] ?? []);
      if (mounted && list.isNotEmpty) {
        setState(() { _schedule = list; _loading = false; });
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
          child: _schedule.isEmpty && !_loading
              ? const Center(child: Text('No active groups found', style: TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText)))
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
            : Icons.schedule_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: status == 'current' ? Border.all(color: AppTheme.primary, width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['group_name'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: AppTheme.darkText, fontSize: 14)),
                const SizedBox(height: 2),
                Text('Position ${item['position_in_cycle']}  •  ${item['projected_date'] ?? '—'}', style: const TextStyle(color: AppTheme.grayText, fontSize: 12, fontFamily: 'Poppins')),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('ETB ${item['estimated_payout_amount'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: AppTheme.darkText, fontSize: 14)),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
