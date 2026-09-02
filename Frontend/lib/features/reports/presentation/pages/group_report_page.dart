import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../../data/reports_service.dart';

class GroupReportPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  const GroupReportPage({super.key, required this.groupId, required this.groupName});

  @override
  State<GroupReportPage> createState() => _GroupReportPageState();
}

class _GroupReportPageState extends State<GroupReportPage> {
  final _service = ReportsService();
  Map<String, dynamic> _report = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.getGroupSummary(widget.groupId);
      if (mounted) setState(() { _report = data; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() { _loading = false; _error = 'Failed to load group report'; });
        ErrorSnackbar.show(context, 'Failed to load group report');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = List<Map<String, dynamic>>.from(_report['member_payment_statuses'] ?? []);
    final overdue = List<Map<String, dynamic>>.from(_report['overdue_contributions'] ?? []);
    final pct = (_report['cycle_completion_percentage'] ?? 0).toDouble();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.groupName, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _loading,
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
            : RefreshIndicator(
                onRefresh: _load,
                color: AppTheme.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _StatCard(label: 'Total Collected', value: 'ETB ${_fmt(_report['total_collected'] ?? 0)}', color: AppTheme.secondary, icon: Icons.savings_rounded)),
                          const SizedBox(width: 12),
                          Expanded(child: _StatCard(label: 'Total Paid Out', value: 'ETB ${_fmt(_report['total_paid_out'] ?? 0)}', color: AppTheme.primary, icon: Icons.send_rounded)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _StatCard(label: 'Remaining Cycles', value: '${_report['remaining_cycles'] ?? 0}', color: const Color(0xFF7C3AED), icon: Icons.loop_rounded)),
                          const SizedBox(width: 12),
                          Expanded(child: _StatCard(label: 'Cycle Progress', value: '${pct.toInt()}%', color: AppTheme.primary, icon: Icons.pie_chart_rounded)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('Cycle Completion', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.darkText)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Payment Progress', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppTheme.grayText)),
                                Text('${pct.toInt()}%', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: AppTheme.primary)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: pct / 100,
                              backgroundColor: const Color(0xFFE5E7EB),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ],
                        ),
                      ),
                      if (members.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text('Member Payment Status', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.darkText)),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                          child: Column(
                            children: members.asMap().entries.map((e) {
                              final m = e.value;
                              final isPaid = m['status'] == 'paid';
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isPaid ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.error.withValues(alpha: 0.1),
                                  child: Icon(isPaid ? Icons.check_rounded : Icons.close_rounded, color: isPaid ? AppTheme.success : AppTheme.error, size: 18),
                                ),
                                title: Text(m['member_name'] ?? 'â€”', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14)),
                                subtitle: Text(isPaid ? 'Paid' : (m['status'] == 'overdue' ? 'Overdue' : 'Pending'), style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: isPaid ? AppTheme.success : AppTheme.error)),
                                trailing: Text('ETB ${m['amount'] ?? 0}', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13)),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                      if (overdue.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text('Overdue Contributions', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.error)),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.error.withValues(alpha: 0.3))),
                          child: Column(
                            children: overdue.map((o) => ListTile(
                              leading: const Icon(Icons.warning_amber_rounded, color: AppTheme.error),
                              title: Text(o['member_name'] ?? 'â€”', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Text('Due: ${o['due_date'] ?? 'â€”'}', style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 12)),
                              trailing: Text('ETB ${o['amount'] ?? 0}', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: AppTheme.error, fontSize: 13)),
                            )).toList(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/reports/export'),
                          icon: const Icon(Icons.download_rounded, color: AppTheme.primary),
                          label: const Text('Export Report', style: TextStyle(fontFamily: 'Poppins', color: AppTheme.primary, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppTheme.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  String _fmt(dynamic val) {
    try { return double.parse(val.toString()).toStringAsFixed(2); } catch (_) { return val.toString(); }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkText)),
          Text(label, style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 11)),
        ],
      ),
    );
  }
}

