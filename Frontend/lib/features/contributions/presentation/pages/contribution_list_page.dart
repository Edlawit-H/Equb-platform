import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../data/contributions_service.dart';

class ContributionListPage extends StatefulWidget {
  const ContributionListPage({super.key});

  @override
  State<ContributionListPage> createState() => _ContributionListPageState();
}

class _ContributionListPageState extends State<ContributionListPage> with SingleTickerProviderStateMixin {
  final _service = ContributionsService();
  late TabController _tabs;
  final Map<String, List<Map<String, dynamic>>> _data = {
    'upcoming': [],
    'history': [],
    'overdue': [],
  };
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getPending(),
        _service.getContributions(status: 'paid'),
        _service.getOverdue(),
      ]);
      if (mounted) {
        setState(() {
          _data['upcoming'] = List<Map<String, dynamic>>.from(results[0]['contributions'] ?? []);
          _data['history'] = List<Map<String, dynamic>>.from(results[1]['contributions'] ?? []);
          _data['overdue'] = List<Map<String, dynamic>>.from(results[2]['contributions'] ?? []);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load contributions';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Contributions', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.grayText,
          indicatorColor: AppTheme.primary,
          labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [Tab(text: 'Upcoming'), Tab(text: 'History'), Tab(text: 'Overdue')],
        ),
      ),
      body: LoadingOverlay(
        isLoading: _loading,
        child: TabBarView(
          controller: _tabs,
          children: [
            _ContributionTab(
              items: _data['upcoming']!,
              type: 'upcoming',
              error: _error,
              onRefresh: _load,
            ),
            _ContributionTab(
              items: _data['history']!,
              type: 'history',
              error: _error,
              onRefresh: _load,
            ),
            _ContributionTab(
              items: _data['overdue']!,
              type: 'overdue',
              error: _error,
              onRefresh: _load,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContributionTab extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String type;
  final String? error;
  final Future<void> Function() onRefresh;

  const _ContributionTab({
    required this.items,
    required this.type,
    this.error,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 36),
            const SizedBox(height: 10),
            Text(error!, style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.error, fontSize: 13)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: onRefresh,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text('Retry', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'upcoming'
                  ? Icons.event_available_rounded
                  : type == 'history'
                      ? Icons.history_rounded
                      : Icons.alarm_on_rounded,
              size: 48,
              color: AppTheme.grayText.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              type == 'upcoming'
                  ? 'No upcoming contributions'
                  : type == 'history'
                      ? 'No contribution history yet'
                      : 'No overdue contributions 🎉',
              style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _ContributionCard(item: items[i], type: type),
      ),
    );
  }
}

class _ContributionCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String type;
  const _ContributionCard({required this.item, required this.type});

  @override
  Widget build(BuildContext context) {
    final isPaid = type == 'history';
    final isOverdue = type == 'overdue';
    final Color badgeColor = isPaid
        ? AppTheme.success
        : isOverdue
            ? AppTheme.error
            : AppTheme.primary;
    final amount = item['amount'];
    final formattedAmount = (amount is num ? amount.toDouble() : double.tryParse('$amount') ?? 0.0).toStringAsFixed(0);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/contributions/${item['contribution_id']}'),
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
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPaid
                    ? Icons.check_circle_rounded
                    : isOverdue
                        ? Icons.warning_rounded
                        : Icons.access_time_rounded,
                color: badgeColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['group_name'] ?? 'Equb Contribution',
                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.darkText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Cycle ${item['cycle_number']} • Due ${item['due_date'] ?? '—'}',
                    style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'ETB $formattedAmount',
                  style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkText),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPaid
                        ? 'Paid'
                        : isOverdue
                            ? 'Overdue'
                            : 'Pending',
                    style: TextStyle(fontFamily: 'Poppins', color: badgeColor, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
