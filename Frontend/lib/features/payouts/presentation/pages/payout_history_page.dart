import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../data/payouts_service.dart';
import 'payout_detail_page.dart';
import 'payout_schedule_page.dart';

class PayoutHistoryPage extends StatefulWidget {
  final String? groupId;

  const PayoutHistoryPage({super.key, this.groupId});

  @override
  State<PayoutHistoryPage> createState() => _PayoutHistoryPageState();
}

class _PayoutHistoryPageState extends State<PayoutHistoryPage> {
  final _service = PayoutsService();
  List<Map<String, dynamic>> _payouts = [];
  bool _loading = true;
  String? _error;

  static const Color primaryOrange = Color(0xFFF97316);
  static const Color activeGreen = Color(0xFF16A34A);
  static const Color textDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);

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
      final data = (widget.groupId != null && widget.groupId!.isNotEmpty)
          ? await _service.getGroupPayouts(widget.groupId!)
          : await _service.getHistory();

      final dynamic payoutsRaw = data['payouts'] ?? data['data']?['payouts'] ?? (data['data'] is List ? data['data'] : null);
      final list = payoutsRaw is List ? List<Map<String, dynamic>>.from(payoutsRaw) : <Map<String, dynamic>>[];

      if (mounted) {
        setState(() {
          _payouts = list;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading payout history: $e");
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load payout history';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalDisbursed = 0;
    for (final p in _payouts) {
      final amt = p['payout_amount'];
      totalDisbursed += amt is num ? amt.toDouble() : double.tryParse('$amt') ?? 0.0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Payout History',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFEA580C),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.timeline_rounded, color: Colors.white),
            tooltip: 'View Timeline Schedule',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PayoutSchedulePage(groupId: widget.groupId)),
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _loading,
        child: RefreshIndicator(
          color: primaryOrange,
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              // Summary Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF334155)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: activeGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Icon(Icons.monetization_on_rounded, color: Color(0xFF4ADE80), size: 28),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Payouts Disbursed',
                            style: TextStyle(fontFamily: 'Poppins', color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            'ETB ${totalDisbursed.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${_payouts.length} completed payout records',
                            style: const TextStyle(fontFamily: 'Poppins', color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Quick Action Button to Schedule
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PayoutSchedulePage(groupId: widget.groupId)),
                      ),
                      icon: const Icon(Icons.timeline_rounded, color: primaryOrange, size: 18),
                      label: const Text(
                        'View Payout Timeline Schedule',
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: primaryOrange, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: primaryOrange),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 36),
                        const SizedBox(height: 10),
                        Text(_error!, style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.error)),
                        const SizedBox(height: 10),
                        ElevatedButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              else if (_payouts.isEmpty && !_loading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.savings_rounded, size: 56, color: textMuted.withValues(alpha: 0.4)),
                        const SizedBox(height: 14),
                        const Text(
                          'No Completed Payouts Yet',
                          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16, color: textDark),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'When cycles complete and winning members receive their payout, records will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Poppins', color: textMuted, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._payouts.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PayoutHistoryCard(
                        payout: p,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PayoutDetailPage(
                              payoutId: p['payout_id']?.toString() ?? '',
                              payoutData: p,
                            ),
                          ),
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayoutHistoryCard extends StatelessWidget {
  final Map<String, dynamic> payout;
  final VoidCallback onTap;

  const _PayoutHistoryCard({required this.payout, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final amount = payout['payout_amount'];
    final formattedAmount = (amount is num ? amount.toDouble() : double.tryParse('$amount') ?? 0.0).toStringAsFixed(2);
    final dateStr = (payout['payout_date'] ?? '').toString().split('T').first;
    final recipientName = payout['recipient_name'] ?? 'Recipient';
    final groupName = payout['group_name'] ?? 'Equb Circle';
    final cycleNum = payout['cycle_number'] ?? 1;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.call_received_rounded, color: Color(0xFF16A34A), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipientName,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Text(
                    '$groupName • Round #$cycleNum',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                  if (dateStr.isNotEmpty)
                    Text(
                      'Paid: $dateStr',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFF9CA3AF),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+ETB $formattedAmount',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'COMPLETED',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF16A34A),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
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
