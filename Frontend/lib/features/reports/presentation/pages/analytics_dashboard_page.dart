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
    'total_contributed': 0.0,
    'total_received': 0.0,
    'wallet_balance': 0.0,
    'total_contributions_paid': 0,
    'active_group_count': 0,
    'completed_group_count': 0,
  };
  List<Map<String, dynamic>> _monthly = [];
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
      final results = await Future.wait([
        _service.getUserSummary(),
        _service.getAnalytics(),
      ]);
      if (mounted) {
        setState(() {
          _summary = results[0];
          _monthly = List<Map<String, dynamic>>.from(results[1]['monthly_contributions'] ?? []);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load financial analytics';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contributed = _summary['total_contributed'] ?? 0;
    final payouts = _summary['total_received'] ?? 0;
    final balance = _summary['wallet_balance'] ?? 0;
    final paidCount = _summary['total_contributions_paid'] ?? 0;

    final cVal = (contributed is num ? contributed.toDouble() : double.tryParse('$contributed') ?? 0.0);
    final pVal = (payouts is num ? payouts.toDouble() : double.tryParse('$payouts') ?? 0.0);
    final bVal = (balance is num ? balance.toDouble() : double.tryParse('$balance') ?? 0.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Financial Analytics',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Export Statement',
            onPressed: () => Navigator.pushNamed(context, '/reports/export'),
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.file_download_outlined, color: AppTheme.primary, size: 20),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _loading,
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppTheme.error, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_error!,
                              style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.error, fontSize: 12)),
                        ),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Retry',
                              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: AppTheme.error, fontSize: 12)),
                        )
                      ],
                    ),
                  ),

                // Financial Overview Banner
                _OverviewHeroCard(
                  totalContributed: cVal,
                  totalPayouts: pVal,
                  balance: bVal,
                ),

                const SizedBox(height: 18),

                // Compact Modern Metric Grid
                const Text(
                  'Key Performance',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                _MetricPillsGrid(
                  contributed: cVal,
                  payouts: pVal,
                  balance: bVal,
                  paidCount: paidCount,
                ),

                const SizedBox(height: 20),

                // 12-Month Contribution Trend
                _MonthlyTrendChart(monthly: _monthly, loading: _loading),

                const SizedBox(height: 20),

                // Group Health & Activity
                _GroupParticipationCard(summary: _summary),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewHeroCard extends StatelessWidget {
  final double totalContributed;
  final double totalPayouts;
  final double balance;

  const _OverviewHeroCard({
    required this.totalContributed,
    required this.totalPayouts,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final netTurnover = totalContributed + totalPayouts;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Savings Turnover',
                style: TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_graph_rounded, color: Color(0xFFFF8A48), size: 13),
                    SizedBox(width: 4),
                    Text('Live Stats', style: TextStyle(color: Color(0xFFFF8A48), fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ETB ${netTurnover.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniStat('Contributed', 'ETB ${totalContributed.toStringAsFixed(0)}', const Color(0xFFF87171)),
                Container(height: 24, width: 1, color: Colors.white.withValues(alpha: 0.12)),
                _miniStat('Received', 'ETB ${totalPayouts.toStringAsFixed(0)}', const Color(0xFF4ADE80)),
                Container(height: 24, width: 1, color: Colors.white.withValues(alpha: 0.12)),
                _miniStat('In Wallet', 'ETB ${balance.toStringAsFixed(0)}', const Color(0xFF60A5FA)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Poppins', fontSize: 11)),
      ],
    );
  }
}

class _MetricPillsGrid extends StatelessWidget {
  final double contributed;
  final double payouts;
  final double balance;
  final int paidCount;

  const _MetricPillsGrid({
    required this.contributed,
    required this.payouts,
    required this.balance,
    required this.paidCount,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.1,
      children: [
        _MetricPill(
          title: 'Contributed',
          value: 'ETB ${contributed.toStringAsFixed(0)}',
          icon: Icons.arrow_upward_rounded,
          iconColor: const Color(0xFFDC2626),
          bgColor: const Color(0xFFFEF2F2),
        ),
        _MetricPill(
          title: 'Payouts Won',
          value: 'ETB ${payouts.toStringAsFixed(0)}',
          icon: Icons.arrow_downward_rounded,
          iconColor: const Color(0xFF16A34A),
          bgColor: const Color(0xFFF0FDF4),
        ),
        _MetricPill(
          title: 'Wallet Balance',
          value: 'ETB ${balance.toStringAsFixed(0)}',
          icon: Icons.account_balance_wallet_rounded,
          iconColor: AppTheme.primary,
          bgColor: const Color(0xFFFFF7ED),
        ),
        _MetricPill(
          title: 'Rounds Paid',
          value: '$paidCount Cycles',
          icon: Icons.verified_rounded,
          iconColor: const Color(0xFF2563EB),
          bgColor: const Color(0xFFEFF6FF),
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _MetricPill({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> monthly;
  final bool loading;

  const _MonthlyTrendChart({required this.monthly, required this.loading});

  @override
  Widget build(BuildContext context) {
    final double maxVal = monthly.fold(0.0, (prev, e) {
      final a = e['total_amount'];
      final val = (a is num ? a.toDouble() : double.tryParse('$a') ?? 0.0);
      return val > prev ? val : prev;
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contribution Activity',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Monthly savings history',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Last 12 Months',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (monthly.isEmpty && !loading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(Icons.insert_chart_outlined_rounded, size: 28, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'No contribution history yet',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your monthly savings chart will populate as you contribute.',
                    style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF94A3B8), fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 170,
              child: BarChart(
                BarChartData(
                  maxY: maxVal > 0 ? maxVal * 1.2 : 1000,
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF0F172A),
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          'ETB ${rod.toY.toStringAsFixed(0)}',
                          const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                  barGroups: monthly.asMap().entries.map((e) {
                    final a = e.value['total_amount'];
                    final val = (a is num ? a.toDouble() : double.tryParse('$a') ?? 0.0);
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: val,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEA580C), Color(0xFFFF8A48)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (val, _) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < monthly.length) {
                            final m = monthly[idx]['month']?.toString().split('-').last ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                m,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxVal > 0 ? maxVal / 3 : 300,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: Color(0xFFF1F5F9),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupParticipationCard extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _GroupParticipationCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final active = summary['active_group_count'] ?? 0;
    final completed = summary['completed_group_count'] ?? 0;
    final total = active + completed;
    final progress = total > 0 ? (completed / total) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Equb Participation',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF0F172A),
                ),
              ),
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/groups'),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Groups',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppTheme.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Completion Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),

          // Row Items
          _statLine(
            'Total Circles Joined',
            '$total Circles',
            icon: Icons.hub_rounded,
            iconColor: const Color(0xFF64748B),
          ),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          _statLine(
            'Active Participating',
            '$active Active',
            icon: Icons.radio_button_checked_rounded,
            iconColor: AppTheme.primary,
            valueColor: AppTheme.primary,
          ),
          const Divider(height: 18, color: Color(0xFFF1F5F9)),
          _statLine(
            'Completed Rounds',
            '$completed Done',
            icon: Icons.check_circle_rounded,
            iconColor: const Color(0xFF16A34A),
            valueColor: const Color(0xFF16A34A),
          ),
        ],
      ),
    );
  }

  Widget _statLine(String label, String value, {required IconData icon, required Color iconColor, Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: valueColor ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
