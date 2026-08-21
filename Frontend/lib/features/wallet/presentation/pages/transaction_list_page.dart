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
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;
  String _filter = 'all';
  String? _error;

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.getTransactions(type: _typeParam);
      final list = List<Map<String, dynamic>>.from(data['transactions'] ?? []);
      if (mounted) {
        setState(() {
          _transactions = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load transactions';
        });
      }
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
            _FilterChips(
              current: _filter,
              onChanged: (v) {
                setState(() => _filter = v);
                _load();
              },
            ),
            Expanded(
              child: _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 40),
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.error, fontSize: 14)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _load,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Retry', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
                          ),
                        ],
                      ),
                    )
                  : filtered.isEmpty && !_loading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppTheme.grayText.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.receipt_long_rounded, color: AppTheme.grayText, size: 32),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No transactions found',
                                style: TextStyle(fontFamily: 'Poppins', color: AppTheme.darkText, fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Your deposits, payouts and debits will appear here.',
                                style: TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: AppTheme.primary,
                          onRefresh: () => _load(),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) => _TransactionTile(
                              tx: filtered[i],
                              onTap: () => Navigator.pushNamed(context, '/transactions/${filtered[i]['transaction_id']}'),
                            ),
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
    final filters = [
      {'id': 'all', 'label': 'All'},
      {'id': 'credits', 'label': 'Credits (+)'},
      {'id': 'debits', 'label': 'Debits (-)'},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: filters.map((f) {
          final isSelected = current == f['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                f['label']!,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.grayText,
                ),
              ),
              selected: isSelected,
              selectedColor: AppTheme.primary,
              backgroundColor: AppTheme.background,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onSelected: (_) => onChanged(f['id']!),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  final VoidCallback onTap;
  const _TransactionTile({required this.tx, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCredit = tx['type'] == 'payout_credit' || tx['type'] == 'top_up';
    final Color color = isCredit ? AppTheme.success : AppTheme.error;
    final amountVal = tx['amount'];
    final formattedAmount = (amountVal is num ? amountVal.toDouble() : double.tryParse('$amountVal') ?? 0.0).toStringAsFixed(2);
    final dateStr = (tx['created_at'] ?? '').toString().split('T').first;

    return GestureDetector(
      onTap: onTap,
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx['group_name'] ?? _label(tx['type'] ?? ''),
                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.darkText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr.isNotEmpty ? dateStr : '—',
                    style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              '${isCredit ? '+' : '-'}ETB $formattedAmount',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14, color: color),
            ),
          ],
        ),
      ),
    );
  }

  String _label(String type) {
    switch (type) {
      case 'top_up':
        return 'Wallet Top-Up';
      case 'contribution_debit':
        return 'Contribution Payment';
      case 'payout_credit':
        return 'Payout Received';
      default:
        return 'Transaction';
    }
  }
}
