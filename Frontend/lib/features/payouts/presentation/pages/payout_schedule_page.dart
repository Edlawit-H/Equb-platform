import 'package:flutter/material.dart';
import '../../data/payouts_service.dart';
import 'payout_history_page.dart';

class PayoutSchedulePage extends StatefulWidget {
  final String? groupId;
  final String? groupName;

  const PayoutSchedulePage({super.key, this.groupId, this.groupName});

  @override
  State<PayoutSchedulePage> createState() => _PayoutSchedulePageState();
}

class _PayoutSchedulePageState extends State<PayoutSchedulePage> {
  final _service = PayoutsService();

  static const _orange = Color(0xFFF97316);
  static const _darkOrange = Color(0xFFEA580C);
  static const _green = Color(0xFF16A34A);
  static const _dark = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);

  Map<String, dynamic>? _data;

  // Safely converts String, int, or double from JSON to double
  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.groupId == null || widget.groupId!.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No group selected.';
      });
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final result = await _service.getGroupSchedule(widget.groupId!);
      if (mounted) setState(() { _data = result; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupName = _data?['group_name'] ?? widget.groupName ?? 'Equb Group';
    final schedule = _data != null
        ? List<Map<String, dynamic>>.from(_data!['schedule'] ?? [])
        : <Map<String, dynamic>>[];
    final currentCycle = _data?['current_cycle'] ?? 1;
    final totalCycles = _data?['total_cycles'] ?? schedule.length;
    final estPayout = _data?['estimated_payout_per_cycle'];
    final estPayoutStr = estPayout != null
        ? 'ETB ${_toDouble(estPayout).toStringAsFixed(0)}'
        : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Payout Schedule',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: _darkOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            tooltip: 'Payout History',
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => PayoutHistoryPage(groupId: widget.groupId))),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _orange))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  color: _orange,
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    children: [
                      _buildHeader(groupName, currentCycle, totalCycles, estPayoutStr),
                      const SizedBox(height: 20),
                      if (schedule.isEmpty)
                        _buildEmpty()
                      else
                        ...List.generate(schedule.length, (i) =>
                          _buildRow(schedule[i], i == schedule.length - 1)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader(String groupName, dynamic currentCycle, dynamic totalCycles, String estPayout) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_darkOrange, _orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _orange.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(groupName,
            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 20, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Cycle $currentCycle of $totalCycles',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white70)),
          if (estPayout.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Pool per round: $estPayout',
              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> item, bool isLast) {
    final status = (item['status'] ?? 'upcoming').toString();
    final isCompleted = status == 'completed';
    final isCurrent = status == 'current';

    final color = isCompleted ? _green : isCurrent ? _orange : _muted;
    final bgColor = isCompleted
        ? const Color(0xFFDCFCE7)
        : isCurrent
            ? const Color(0xFFFFF7ED)
            : const Color(0xFFF1F5F9);
    final icon = isCompleted
        ? Icons.check_circle_rounded
        : isCurrent
            ? Icons.star_rounded
            : Icons.schedule_rounded;

    final cycle = item['cycle_number'] ?? 0;
    final total = item['total_cycles'] ?? 0;
    final name = item['recipient_name'] ?? 'Member #$cycle';
    final date = item['projected_date'] ?? 'Pending Start';
    final amount = item['payout_amount'];
    final amountStr = amount != null
        ? 'ETB ${_toDouble(amount).toStringAsFixed(0)}'
        : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline dot + line
        SizedBox(
          width: 32,
          child: Column(
            children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: isCurrent ? 2.5 : 1.5),
                ),
                child: Icon(icon, color: color, size: 15),
              ),
              if (!isLast)
                Container(
                  width: 2, height: 100,
                  color: isCompleted ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Card
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCurrent ? _orange : isCompleted ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                  width: isCurrent ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isCurrent ? _orange.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8, offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Round $cycle of $total',
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 12, color: color),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          isCompleted ? 'PAID' : isCurrent ? 'ACTIVE' : 'UPCOMING',
                          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 10, color: color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: bgColor,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'M',
                          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: color, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: _dark)),
                            Text(date,
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: _muted)),
                          ],
                        ),
                      ),
                      if (amountStr.isNotEmpty)
                        Text(amountStr,
                          style: TextStyle(
                            fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 14,
                            color: isCompleted ? _green : _dark,
                          )),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 48),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Poppins', color: _muted, fontSize: 14)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: _orange, foregroundColor: Colors.white),
              child: const Text('Retry', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.calendar_month_rounded, size: 60, color: _muted.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text('No Schedule Yet',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16, color: _dark)),
            const SizedBox(height: 6),
            const Text(
              'The group needs to be started before the payout timeline is generated.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Poppins', color: _muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}