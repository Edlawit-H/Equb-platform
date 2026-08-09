import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../data/reports_service.dart';

class AnalyticsDashboardPage extends StatefulWidget {
  const AnalyticsDashboardPage({super.key});

  @override
  State<AnalyticsDashboardPage> createState() => _AnalyticsDashboardPageState();
}

class _AnalyticsDashboardPageState extends State<AnalyticsDashboardPage> {
  final _service = ReportsService();
  Map<String, dynamic> _summary = {
    'total_contributed': 45000.0,
    'total_payouts_received': 60000.0,
    'wallet_balance': 12500.0,
    'total_contributions_paid': 45,
    'group_stats': {
      'total_groups_joined': 4,
      'active_groups': 3,
      'completed_groups': 1,
    }
  };
  List<Map<String, dynamic>> _monthly = [
    {'month': '2026-03', 'total_amount': 2000.0},
    {'month': '2026-04', 'total_amount': 4000.0},
    {'month': '2026-05', 'total_amount': 3500.0},
    {'month': '2026-06', 'total_amount': 5000.0},
    {'month': '2026-07', 'total_amount': 6000.0},
    {'month': '2026-08', 'total_amount': 7500.0},
  ];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _service.getUserSummary(),
        _service.getAnalytics(),
      ]);
      if (mounted && results[0].isNotEmpty) {
        setState(() {
          _summary = results[0];
          _monthly = List<Map<String, dynamic>>.from(results[1]['monthly_contributions'] ?? _monthly);
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
        title: const Text('Analytics', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/reports/export'),
            icon: const Icon(Icons.download_rounded, color: AppTheme.primary, size: 18),
            label: const Text('Export', style: TextStyle(fontFamily: 'Poppins', color: AppTheme.primary, fontWeight: FontWeight.w600)),
          ),
        ],
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryCards(summary: _summary),
                const SizedBox(height: 20),
                if (_monthly.isNotEmpty) _MonthlyChart(monthly: _monthly),
                const SizedBox(height: 20),
                _GroupStats(summary: _summary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _SummaryCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        _StatCard('Total Contributed', 'ETB ${((summary['total_contributed']) ?? 0).toDouble().toStringAsFixed(0)}', AppTheme.primary, Icons.arrow_upward_rounded),
        _StatCard('Payouts Received', 'ETB ${((summary['total_payouts_received']) ?? 0).toDouble().toStringAsFixed(0)}', AppTheme.success, Icons.arrow_downward_rounded),
        _StatCard('Wallet Balance', 'ETB ${((summary['wallet_balance']) ?? 0).toDouble().toStringAsFixed(0)}', const Color(0xFF7C3AED), Icons.account_balance_wallet_rounded),
        _StatCard('Payments Made', '${summary['total_contributions_paid'] ?? 0}', AppTheme.secondary, Icons.receipt_rounded),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCard(this.label, this.value, this.color, this.icon);

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
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(value, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: color, fontSize: 16)),
          Text(label, style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 11)),
        ],
      ),
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  final List<Map<String, dynamic>> monthly;
  const _MonthlyChart({required this.monthly});

  @override
  Widget build(BuildContext context) {
    final bars = monthly.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [BarChartRodData(
          toY: (e.value['total_amount'] ?? 0).toDouble(),
          color: AppTheme.primary,
          width: 14,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        )],
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Monthly Contributions', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppTheme.darkText, fontSize: 15)),
          const SizedBox(height: 4),
          const Text('Last 12 months', style: TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 12)),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(BarChartData(
              barGroups: bars,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1000),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10, fontFamily: 'Poppins', color: AppTheme.grayText)))),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx >= 0 && idx < monthly.length) {
                    final month = (monthly[idx]['month'] ?? '').toString();
                    return Padding(padding: const EdgeInsets.only(top: 4), child: Text(month.length >= 7 ? month.substring(5) : month, style: const TextStyle(fontSize: 9, fontFamily: 'Poppins', color: AppTheme.grayText)));
                  }
                  return const SizedBox();
                })),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
            )),
          ),
        ],
      ),
    );
  }
}

class _GroupStats extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _GroupStats({required this.summary});

  @override
  Widget build(BuildContext context) {
    final gs = summary['group_stats'] as Map<String, dynamic>? ?? {};
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Group Participation', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppTheme.darkText, fontSize: 15)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _GroupStat('Total Joined', '${gs['total_groups_joined'] ?? 0}', AppTheme.primary)),
              Expanded(child: _GroupStat('Active', '${gs['active_groups'] ?? 0}', AppTheme.secondary)),
              Expanded(child: _GroupStat('Completed', '${gs['completed_groups'] ?? 0}', AppTheme.success)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _GroupStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 22, color: color)),
        Text(label, style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 11)),
      ],
    );
  }
}
