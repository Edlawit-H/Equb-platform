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
  Map<String, List<Map<String, dynamic>>> _data = {
    'upcoming': [
      {
        'contribution_id': 'cb-101',
        'group_name': 'Weekly Savings Equb',
        'cycle_number': 2,
        'amount': 1000.0,
        'due_date': '2026-08-15',
        'status': 'pending',
      },
    ],
    'history': [
      {
        'contribution_id': 'cb-100',
        'group_name': 'Weekly Savings Equb',
        'cycle_number': 1,
        'amount': 1000.0,
        'due_date': '2026-08-01',
        'paid_date': '2026-08-01',
        'status': 'paid',
      },
    ],
    'overdue': [],
  };
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _service.getPending(),
        _service.getContributions(status: 'paid'),
        _service.getOverdue(),
      ]);
      if (mounted) {
        setState(() {
          _data['upcoming'] = List<Map<String, dynamic>>.from(results[0]['contributions'] ?? _data['upcoming']!);
          _data['history'] = List<Map<String, dynamic>>.from(results[1]['contributions'] ?? _data['history']!);
          _data['overdue'] = List<Map<String, dynamic>>.from(results[2]['contributions'] ?? _data['overdue']!);
          _loading = false;
        });
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
            _ContributionTab(items: _data['upcoming']!, type: 'upcoming', onRefresh: _load),
            _ContributionTab(items: _data['history']!, type: 'history', onRefresh: _load),
            _ContributionTab(items: _data['overdue']!, type: 'overdue', onRefresh: _load),
          ],
        ),
      ),
    );
  }
}

class _ContributionTab extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String type;
  final Future<void> Function() onRefresh;
  const _ContributionTab({required this.items, required this.type, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 60, color: AppTheme.grayText.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text('No $type contributions', style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText)),
        ],
      ));
    }
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _ContributionCard(
          item: items[i],
          type: type,
          onTap: () => Navigator.pushNamed(context, '/contributions/${items[i]['contribution_id']}'),
        ),
      ),
    );
  }
}

class _ContributionCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String type;
  final VoidCallback onTap;
  const _ContributionCard({required this.item, required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = item['status'] ?? 'pending';
    final Color statusColor = status == 'paid'
        ? AppTheme.success
        : status == 'overdue'
            ? AppTheme.error
            : AppTheme.primary;

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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.payments_rounded, color: statusColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['group_name'] ?? 'Equb Group', style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: AppTheme.darkText, fontSize: 14)),
                  Text('Cycle ${item['cycle_number'] ?? 1}  •  Due: ${item['due_date'] ?? '—'}', style: const TextStyle(color: AppTheme.grayText, fontSize: 12, fontFamily: 'Poppins')),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('ETB ${item['amount'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: AppTheme.darkText, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
