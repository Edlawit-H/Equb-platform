import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../../data/contributions_service.dart';

class OverdueContributionsPage extends StatefulWidget {
  const OverdueContributionsPage({super.key});

  @override
  State<OverdueContributionsPage> createState() => _OverdueContributionsPageState();
}

class _OverdueContributionsPageState extends State<OverdueContributionsPage> {
  final _service = ContributionsService();
  List<Map<String, dynamic>> _overdue = [];
  bool _loading = true;
  bool _paying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.getOverdue();
      if (mounted) {
        setState(() {
          _overdue = List<Map<String, dynamic>>.from(data['contributions'] ?? []);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _loading = false; _error = 'Failed to load overdue contributions'; });
      }
    }
  }

  Future<void> _payOne(Map<String, dynamic> contribution) async {
    final result = await Navigator.pushNamed(context, '/contributions/pay', arguments: contribution);
    if (result == true) _load();
  }

  Future<void> _payAll() async {
    if (_overdue.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pay All Overdue', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: Text('Pay all ${_overdue.length} overdue contributions?', style: const TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Pay All', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _paying = true);
    int paid = 0;
    for (final c in _overdue) {
      try {
        await _service.pay(c['group_id'], c['cycle_number'] as int);
        paid++;
      } catch (_) {}
    }
    setState(() => _paying = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$paid contribution(s) paid'), backgroundColor: AppTheme.success),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Overdue Contributions', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _loading || _paying,
        child: _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.error),
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              )
            : _overdue.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle_rounded, size: 64, color: AppTheme.success),
                        SizedBox(height: 16),
                        Text('No overdue contributions', style: TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 16, fontWeight: FontWeight.w600)),
                        SizedBox(height: 6),
                        Text('You are all caught up!', style: TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 13)),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _load,
                          color: AppTheme.primary,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _overdue.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (ctx, i) {
                              final c = _overdue[i];
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44, height: 44,
                                      decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                      child: const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 22),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(c['group_name'] ?? 'â€”', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.darkText)),
                                          Text('Due: ${c['due_date'] ?? 'â€”'} Â· Cycle ${c['cycle_number'] ?? 1}', style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.error, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('ETB ${c['amount'] ?? 0}', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: AppTheme.darkText, fontSize: 14)),
                                        const SizedBox(height: 4),
                                        GestureDetector(
                                          onTap: () => _payOne(c),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
                                            child: const Text('Pay', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _paying ? null : _payAll,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.error,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text('Pay All (${_overdue.length})', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

