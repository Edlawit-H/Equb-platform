import 'package:flutter/material.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../data/payouts_service.dart';
import 'payout_received_page.dart';

class PayoutDetailPage extends StatefulWidget {
  final String payoutId;
  final Map<String, dynamic>? payoutData;

  const PayoutDetailPage({
    super.key,
    required this.payoutId,
    this.payoutData,
  });

  @override
  State<PayoutDetailPage> createState() => _PayoutDetailPageState();
}

class _PayoutDetailPageState extends State<PayoutDetailPage> {
  final _service = PayoutsService();
  Map<String, dynamic>? _payout;
  bool _loading = true;
  bool _isApproving = false;

  static const Color primaryOrange = Color(0xFFF97316);
  static const Color activeGreen = Color(0xFF16A34A);
  static const Color textDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    if (widget.payoutData != null && widget.payoutData!.isNotEmpty) {
      _payout = Map<String, dynamic>.from(widget.payoutData!);
      _loading = false;
    }
    if (widget.payoutId.isNotEmpty) {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final data = await _service.getById(widget.payoutId);
      if (mounted) {
        setState(() {
          _payout = {
            ...?_payout,
            ...Map<String, dynamic>.from(data['payout'] ?? {}),
          };
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _handleApprovePayout() async {
    final payoutId = _payout?['payout_id']?.toString() ?? widget.payoutId;
    final recipient = _payout?['recipient_name'] ?? 'Recipient';
    final amount = _payout?['payout_amount'] ?? _payout?['estimated_payout_amount'] ?? 0;
    final numAmount = amount is num ? amount.toDouble() : double.tryParse('$amount') ?? 0.0;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: primaryOrange),
            SizedBox(width: 8),
            Text(
              'Approve Payout',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Confirm approving payout of ETB ${numAmount.toStringAsFixed(2)} to $recipient for Cycle ${_payout?['cycle_number'] ?? 1}?\n\nThis will immediately credit their digital wallet balance.',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13.5, color: textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm Approval', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isApproving = true);

    try {
      if (payoutId.isNotEmpty) {
        await _service.approvePayout(payoutId);
      }
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payout of ETB ${numAmount.toStringAsFixed(2)} approved successfully!'),
          backgroundColor: activeGreen,
        ),
      );

      setState(() {
        _payout?['status'] = 'completed';
      });

      // Navigate to winning celebration
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PayoutReceivedPage(
            amount: numAmount,
            groupName: _payout?['group_name'] ?? 'Equb Circle',
            cycleNumber: _payout?['cycle_number'] ?? 1,
            recipientName: recipient,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _payout ?? {};
    final status = (p['status'] ?? 'upcoming').toString().toLowerCase();
    final isCompleted = status == 'completed';
    final isCurrent = status == 'current';

    final amountVal = p['payout_amount'] ?? p['estimated_payout_amount'] ?? 0;
    final double amount = amountVal is num ? amountVal.toDouble() : double.tryParse('$amountVal') ?? 0.0;

    final recipientName = p['recipient_name'] ?? 'Member';
    final groupName = p['group_name'] ?? 'Equb Circle';
    final cycleNum = p['cycle_number'] ?? 1;
    final totalCycles = p['total_cycles'] ?? 1;
    final dateStr = (p['payout_date'] ?? p['projected_date'] ?? 'Upcoming').toString().split('T').first;

    final Color statusColor = isCompleted
        ? const Color(0xFF16A34A)
        : isCurrent
            ? const Color(0xFFF97316)
            : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Payout Details',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFEA580C),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: LoadingOverlay(
        isLoading: _loading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Top Amount Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted
                            ? Icons.check_circle_rounded
                            : isCurrent
                                ? Icons.stars_rounded
                                : Icons.schedule_rounded,
                        color: statusColor,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'ETB ${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins',
                        color: isCompleted ? activeGreen : textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      groupName,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isCompleted
                            ? 'COMPLETED / PAID'
                            : isCurrent
                                ? 'ACTIVE WINNER (CURRENT CYCLE)'
                                : 'SCHEDULED FUTURE PAYOUT',
                        style: TextStyle(
                          color: statusColor,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Recipient Profile Card (Screen 33: Member Receiving Payout)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RECIPIENT MEMBER',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFFFF7ED),
                          child: Text(
                            recipientName.isNotEmpty ? recipientName[0].toUpperCase() : 'M',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: primaryOrange,
                            ),
                          ),
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
                                  fontSize: 16,
                                  color: textDark,
                                ),
                              ),
                              Text(
                                p['recipient_phone'] ?? 'Verified Equb Member',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: primaryOrange.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'Round #$cycleNum',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: primaryOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Detailed Attributes
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildRow('Equb Circle', groupName),
                    const Divider(height: 20),
                    _buildRow('Cycle Round', 'Cycle $cycleNum of $totalCycles'),
                    const Divider(height: 20),
                    _buildRow('Payout Date', dateStr),
                    const Divider(height: 20),
                    _buildRow('Total Pool Amount', 'ETB ${amount.toStringAsFixed(2)}'),
                    const Divider(height: 20),
                    _buildRow('Disbursement Status', isCompleted ? 'Credited to Wallet' : (isCurrent ? 'Ready for Payout' : 'Scheduled')),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              if (isCurrent || (!isCompleted && p['is_admin'] == true)) ...[
                // Screen 34: Approve Payout (Admin) button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isApproving ? null : _handleApprovePayout,
                    icon: _isApproving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                    label: Text(
                      _isApproving ? 'Approving Payout...' : 'Approve Payout (Admin)',
                      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Screen 36: View Celebration Alert Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PayoutReceivedPage(
                        amount: amount,
                        groupName: groupName,
                        cycleNumber: cycleNum,
                        recipientName: recipientName,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.celebration_rounded, color: primaryOrange),
                  label: const Text(
                    'View Payout Celebration / Alert',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: primaryOrange),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryOrange, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Poppins', color: textMuted, fontSize: 13)),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: textDark, fontSize: 13.5),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
