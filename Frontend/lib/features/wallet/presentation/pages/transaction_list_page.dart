import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../data/wallet_service.dart';

class TransactionListPage extends StatefulWidget {
  const TransactionListPage({super.key});

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  final _service = WalletService();
  List<Map<String, dynamic>> _transactions = [
    {
      'transaction_id': 'tx-1001',
      'type': 'top_up',
      'amount': 5000.0,
      'group_name': 'Wallet Top-Up',
      'status': 'completed',
      'created_at': '2026-08-01T10:30:00Z',
    },
    {
      'transaction_id': 'tx-1002',
      'type': 'contribution_debit',
      'amount': 1000.0,
      'group_name': 'Weekly Savings Equb',
      'status': 'completed',
      'created_at': '2026-08-03T14:15:00Z',
    },
    {
      'transaction_id': 'tx-1003',
      'type': 'payout_credit',
      'amount': 12000.0,
      'group_name': 'Monthly Executive Equb',
      'status': 'completed',
      'created_at': '2026-08-05T09:00:00Z',
    },
  ];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? get _typeParam {
    if (_filter == 'credits') return 'payout_credit';
    if (_filter == 'debits') return 'contribution_debit';
    return null;
  }

  Future<void> _load() async {
    try {
      final data = await _service.getTransactions(type: _typeParam);
      final list = List<Map<String, dynamic>>.from(data['transactions'] ?? []);
      if (mounted && list.isNotEmpty) {
        setState(() {
          _transactions = list;
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
    final filtered = _transactions.where((tx) {
      if (_filter == 'credits') return tx['type'] == 'payout_credit' || tx['type'] == 'top_up';
      if (_filter == 'debits') return tx['type'] == 'contribution_debit';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Transactions', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _loading,
        child: Column(
          children: [
            _FilterChips(current: _filter, onChanged: (v) { setState(() => _filter = v); _load(); }),
            Expanded(
              child: filtered.isEmpty && !_loading
                  ? const Center(child: Text('No transactions found', style: TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText)))
                  : RefreshIndicator(
                      color: AppTheme.primary,
                      onRefresh: () => _load(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          return _TxCard(
                            tx: filtered[i],
                            onTap: () => Navigator.pushNamed(context, '/transactions/${filtered[i]['transaction_id']}'),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;
  const _FilterChips({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final filters = [('all', 'All'), ('credits', 'Credits'), ('debits', 'Debits')];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: filters.map((f) {
          final selected = current == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(f.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(f.$2, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13, color: selected ? Colors.white : AppTheme.grayText)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TxCard extends StatelessWidget {
  final Map<String, dynamic> tx;
  final VoidCallback onTap;
  const _TxCard({required this.tx, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCredit = tx['type'] == 'payout_credit' || tx['type'] == 'top_up';
    final amount = tx['amount'] ?? 0;
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
                color: isCredit ? AppTheme.success.withOpacity(0.1) : AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                color: isCredit ? AppTheme.success : AppTheme.error,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_txLabel(tx['type'] ?? ''), style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: AppTheme.darkText, fontSize: 14)),
                  if (tx['group_name'] != null)
                    Text(tx['group_name'], style: const TextStyle(color: AppTheme.grayText, fontSize: 12, fontFamily: 'Poppins')),
                  Text(_formatDate(tx['created_at']), style: const TextStyle(color: AppTheme.grayText, fontSize: 11, fontFamily: 'Poppins')),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : '-'}ETB $amount',
                  style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: isCredit ? AppTheme.success : AppTheme.error, fontSize: 14),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(tx['status'] ?? '', style: const TextStyle(color: AppTheme.success, fontSize: 10, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _txLabel(String type) {
    switch (type) {
      case 'top_up': return 'Wallet Top-Up';
      case 'contribution_debit': return 'Contribution Paid';
      case 'payout_credit': return 'Payout Received';
      default: return 'Adjustment';
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final d = DateTime.parse(date.toString());
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) { return date.toString(); }
  }
}
