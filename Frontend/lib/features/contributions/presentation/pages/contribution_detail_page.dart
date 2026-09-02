import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../../data/contributions_service.dart';

class ContributionDetailPage extends StatefulWidget {
  final String contributionId;
  const ContributionDetailPage({super.key, required this.contributionId});

  @override
  State<ContributionDetailPage> createState() => _ContributionDetailPageState();
}

class _ContributionDetailPageState extends State<ContributionDetailPage> {
  final _service = ContributionsService();
  Map<String, dynamic>? _contribution;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _service.getById(widget.contributionId);
      if (mounted) setState(() { _contribution = data['contribution']; _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); ErrorSnackbar.show(context, 'Failed to load contribution'); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _contribution;
    final isPending = c?['status'] == 'pending' || c?['status'] == 'overdue';
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Contribution Detail', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _loading,
        child: c == null ? const SizedBox() : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _HeaderCard(contribution: c),
              const SizedBox(height: 16),
              _DetailCard(contribution: c),
              if (isPending) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.pushNamed(context, '/contributions/pay', arguments: c);
                      if (result == true) _load();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Pay Now', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Map<String, dynamic> contribution;
  const _HeaderCard({required this.contribution});

  @override
  Widget build(BuildContext context) {
    final status = contribution['status'] ?? 'pending';
    final Color statusColor = status == 'paid' ? AppTheme.success : status == 'overdue' ? AppTheme.error : AppTheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.payments_rounded, color: statusColor, size: 32),
          ),
          const SizedBox(height: 12),
          Text('ETB ${contribution['amount'] ?? 0}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: AppTheme.darkText)),
          const SizedBox(height: 4),
          Text(contribution['group_name'] ?? 'Equb Group', style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 14)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(status, style: TextStyle(color: statusColor, fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final Map<String, dynamic> contribution;
  const _DetailCard({required this.contribution});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          _Row('Group', contribution['group_name'] ?? 'â€”'),
          _Row('Cycle Number', 'Cycle ${contribution['cycle_number'] ?? 1}'),
          _Row('Due Date', contribution['due_date'] ?? 'â€”'),
          _Row('Paid Date', contribution['paid_date'] ?? 'Not paid yet'),
          _Row('Amount', 'ETB ${contribution['amount'] ?? 0}'),
          _Row('Status', contribution['status'] ?? 'â€”'),
          _Row('Contribution ID', _short(contribution['contribution_id'])),
        ],
      ),
    );
  }

  Widget _Row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 13)),
          Flexible(child: Text(value, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppTheme.darkText, fontSize: 13), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  String _short(dynamic id) {
    if (id == null) return 'â€”';
    final s = id.toString();
    return s.length > 12 ? '...${s.substring(s.length - 12)}' : s;
  }
}

