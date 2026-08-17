import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../../data/reports_service.dart';

class PersonalReportPage extends StatefulWidget {
  const PersonalReportPage({super.key});

  @override
  State<PersonalReportPage> createState() => _PersonalReportPageState();
}

class _PersonalReportPageState extends State<PersonalReportPage> {
  final _service = ReportsService();
  Map<String, dynamic> _summary = {};
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
      final data = await _service.getUserSummary();
      if (mounted) setState(() { _summary = data; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() { _loading = false; _error = 'Failed to load report'; });
        ErrorSnackbar.show(context, 'Failed to load personal report');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Personal Report', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
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
                      _WalletCard(balance: _summary['wallet_balance'] ?? 0),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Total Contributed',
                              value: 'ETB ${_fmt(_summary['total_contributed'] ?? 0)}',
                              icon: Icons.arrow_upward_rounded,
                              color: AppTheme.error,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'Total Received',
                              value: 'ETB ${_fmt(_summary['total_received'] ?? 0)}',
                              icon: Icons.arrow_downward_rounded,
                              color: AppTheme.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Active Groups',
                              value: '${_summary['active_group_count'] ?? 0}',
                              icon: Icons.group_rounded,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'Completed',
                              value: '${_summary['completed_group_count'] ?? 0}',
                              icon: Icons.check_circle_rounded,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('Export Report', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.darkText)),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/reports/export'),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFFEA580C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.download_rounded, color: Colors.white, size: 28),
                              SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Download Report', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                                  Text('PDF or Excel format', style: TextStyle(fontFamily: 'Poppins', color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                              Spacer(),
                              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                            ],
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
    try {
      return double.parse(val.toString()).toStringAsFixed(2);
    } catch (_) {
      return val.toString();
    }
  }
}

class _WalletCard extends StatelessWidget {
  final dynamic balance;
  const _WalletCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF334155)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Wallet Balance', style: TextStyle(fontFamily: 'Poppins', color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            'ETB ${double.tryParse(balance.toString())?.toStringAsFixed(2) ?? '0.00'}',
            style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.darkText)),
          Text(label, style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 11)),
        ],
      ),
    );
  }
}
