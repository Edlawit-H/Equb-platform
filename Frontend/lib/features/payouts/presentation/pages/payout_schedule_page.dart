import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../data/payouts_service.dart';
import '../../../groups/data/group_service.dart';
import 'payout_detail_page.dart';
import 'payout_history_page.dart';

class PayoutSchedulePage extends StatefulWidget {
  final String? groupId;
  final String? groupName;

  const PayoutSchedulePage({super.key, this.groupId, this.groupName});

  @override
  State<PayoutSchedulePage> createState() => _PayoutSchedulePageState();
}

class _PayoutSchedulePageState extends State<PayoutSchedulePage> {
  final _payoutsService = PayoutsService();
  final _groupService = GroupService();

  List<Map<String, dynamic>> _schedule = [];
  List<Map<String, dynamic>> _userGroups = [];
  String? _selectedGroupId;
  String _selectedGroupName = '';
  bool _loading = true;
  String? _error;

  static const Color primaryOrange = Color(0xFFF97316);
  static const Color activeGreen = Color(0xFF16A34A);
  static const Color textDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.groupId;
    _selectedGroupName = widget.groupName ?? '';
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Load groups first to populate group selector
      final groupsRes = await _groupService.getGroups().catchError((_) => <String, dynamic>{});
      if (groupsRes['data'] is List) {
        _userGroups = List<Map<String, dynamic>>.from(groupsRes['data']);
      }

      if (_selectedGroupId == null && _userGroups.isNotEmpty) {
        _selectedGroupId = _userGroups.first['group_id']?.toString() ?? _userGroups.first['id']?.toString();
        _selectedGroupName = _userGroups.first['group_name']?.toString() ?? 'Equb Circle';
      }

      await _loadSchedule();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load payout schedule';
        });
      }
    }
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_selectedGroupId != null && _selectedGroupId!.isNotEmpty) {
        final list = await _loadGroupSchedule(_selectedGroupId!);
        if (mounted) {
          setState(() {
            _schedule = list;
            _loading = false;
          });
        }
      } else {
        final rawSchedule = await _payoutsService.getSchedule();
        final list = List<Map<String, dynamic>>.from(rawSchedule['schedule'] ?? []);
        if (mounted) {
          setState(() {
            _schedule = list;
            _loading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading schedule: $e");
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load timeline: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadGroupSchedule(String groupId) async {
    final results = await Future.wait([
      _groupService.getGroupById(groupId).catchError((_) => <String, dynamic>{}),
      _groupService.getGroupMembers(groupId).catchError((_) => <String, dynamic>{}),
      _payoutsService.getGroupPayouts(groupId).catchError((_) => <String, dynamic>{}),
    ]);

    final dynamic groupRaw = results[0]['data'] ?? results[0];
    final group = groupRaw is Map ? Map<String, dynamic>.from(groupRaw) : <String, dynamic>{};

    final dynamic membersRaw = results[1]['data'] ?? results[1];
    final members = membersRaw is List ? List<Map<String, dynamic>>.from(membersRaw) : <Map<String, dynamic>>[];

    final dynamic payoutsRaw = results[2]['payouts'] ?? results[2]['data']?['payouts'] ?? (results[2]['data'] is List ? results[2]['data'] : null);
    final payouts = payoutsRaw is List ? List<Map<String, dynamic>>.from(payoutsRaw) : <Map<String, dynamic>>[];

    final totalCycles = _asInt(group['total_cycles']) ?? _asInt(group['max_members']) ?? (members.isNotEmpty ? members.length : 1);
    final currentCycle = _asInt(group['current_cycle']) ?? 1;
    final cycleDuration = _asInt(group['cycle_duration']) ?? 7;
    final contribAmount = group['contribution_amount'] is num
        ? (group['contribution_amount'] as num).toDouble()
        : double.tryParse('${group['contribution_amount']}') ?? 0.0;
    final estPayout = contribAmount * (members.isNotEmpty ? members.length : (totalCycles > 0 ? totalCycles : 1));

    final startDateStr = group['start_date']?.toString();
    final startDate = startDateStr != null ? DateTime.tryParse(startDateStr) : null;

    final byCyclePayout = <int, Map<String, dynamic>>{
      for (final p in payouts)
        if (_asInt(p['cycle_number']) != null) _asInt(p['cycle_number'])!: p,
    };

    final membersByPos = <int, Map<String, dynamic>>{
      for (int i = 0; i < members.length; i++)
        (_asInt(members[i]['position_in_cycle']) ?? (i + 1)): members[i],
    };

    final effectiveTotal = totalCycles > 0 ? totalCycles : (members.isNotEmpty ? members.length : 1);

    return List.generate(effectiveTotal, (index) {
      final cycle = index + 1;
      final payout = byCyclePayout[cycle];
      final member = membersByPos[cycle];
      final recipientName = payout?['recipient_name'] ??
          member?['full_name'] ??
          member?['name'] ??
          'Member #$cycle';

      DateTime? projDate;
      if (startDate != null) {
        projDate = startDate.add(Duration(days: (cycle - 1) * cycleDuration));
      }

      String status = 'upcoming';
      if (payout?['status'] == 'completed' || cycle < currentCycle) {
        status = 'completed';
      } else if (cycle == currentCycle) {
        status = 'current';
      }

      return {
        'group_id': groupId,
        'group_name': group['group_name'] ?? _selectedGroupName,
        'cycle_number': cycle,
        'total_cycles': effectiveTotal,
        'current_cycle': currentCycle,
        'position_in_cycle': cycle,
        'recipient_name': recipientName,
        'recipient_phone': member?['phone_number'],
        'projected_date': payout?['payout_date'] != null
            ? payout!['payout_date'].toString().split('T').first
            : (projDate != null ? '${projDate.year}-${projDate.month.toString().padLeft(2, '0')}-${projDate.day.toString().padLeft(2, '0')}' : 'Pending Start'),
        'estimated_payout_amount': payout?['payout_amount'] ?? estPayout,
        'status': status,
        'payout_id': payout?['payout_id'],
        'is_admin': group['admin_id'] != null,
      };
    });
  }

  int? _asInt(dynamic value) => value is int ? value : int.tryParse('$value');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Payout Schedule',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFEA580C),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            tooltip: 'Payout History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PayoutHistoryPage()),
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _loading,
        child: RefreshIndicator(
          color: primaryOrange,
          onRefresh: _loadSchedule,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // Group Selector Dropdown
              if (_userGroups.length > 1) _buildGroupSelector(),

              // Schedule Header Summary Banner
              _buildSummaryHeader(),

              const SizedBox(height: 20),

              // Legend
              _buildTimelineLegend(),

              const SizedBox(height: 16),

              // Error or Empty or Timeline
              if (_error != null)
                _buildErrorState()
              else if (_schedule.isEmpty && !_loading)
                _buildEmptyState()
              else
                ..._buildTimelineList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGroupId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: primaryOrange),
          items: _userGroups.map((g) {
            final gid = g['group_id']?.toString() ?? g['id']?.toString() ?? '';
            final gname = g['group_name']?.toString() ?? 'Equb Circle';
            return DropdownMenuItem<String>(
              value: gid,
              child: Row(
                children: [
                  const Icon(Icons.groups_rounded, size: 18, color: primaryOrange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      gname,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (newVal) {
            if (newVal != null && newVal != _selectedGroupId) {
              setState(() {
                _selectedGroupId = newVal;
                final match = _userGroups.firstWhere(
                  (g) => (g['group_id']?.toString() ?? g['id']?.toString()) == newVal,
                  orElse: () => {},
                );
                _selectedGroupName = match['group_name']?.toString() ?? '';
              });
              _loadSchedule();
            }
          },
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    final total = _schedule.length;
    final completedCount = _schedule.where((s) => s['status'] == 'completed').length;
    final currentItem = _schedule.firstWhere((s) => s['status'] == 'current', orElse: () => {});
    final nextAmount = currentItem['estimated_payout_amount'] ?? (_schedule.isNotEmpty ? _schedule.first['estimated_payout_amount'] : 0);

    final formattedAmount = (nextAmount is num ? nextAmount.toDouble() : double.tryParse('$nextAmount') ?? 0.0).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEA580C), Color(0xFFF97316)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryOrange.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ROTATION TIMELINE',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white70,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedGroupName.isNotEmpty ? _selectedGroupName : 'Equb Schedule',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$completedCount / $total Done',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pool Amount per Round',
                    style: TextStyle(fontFamily: 'Poppins', color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    'ETB $formattedAmount',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/payouts/history'),
                icon: const Icon(Icons.receipt_long_rounded, size: 16),
                label: const Text('All Receipts'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primaryOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  elevation: 0,
                  textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _legendItem('Completed (Paid)', activeGreen, Icons.check_circle_rounded),
        _legendItem('Current Cycle', primaryOrange, Icons.stars_rounded),
        _legendItem('Future Payout', const Color(0xFF64748B), Icons.schedule_rounded),
      ],
    );
  }

  Widget _legendItem(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTimelineList() {
    return List.generate(_schedule.length, (index) {
      final item = _schedule[index];
      final isLast = index == _schedule.length - 1;
      return _ScheduleTimelineNode(
        item: item,
        isLast: isLast,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PayoutDetailPage(
                payoutId: item['payout_id']?.toString() ?? '',
                payoutData: item,
              ),
            ),
          ).then((_) => _loadSchedule());
        },
      );
    });
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 40),
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.error)),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _loadSchedule,
              style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
              child: const Text('Retry', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.calendar_month_rounded, size: 60, color: textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text(
              'No Payout Schedule Available',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16, color: textDark),
            ),
            const SizedBox(height: 6),
            const Text(
              'Start the Equb group or wait for the cycle rotation to be generated.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Poppins', color: textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleTimelineNode extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isLast;
  final VoidCallback onTap;

  const _ScheduleTimelineNode({
    required this.item,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = (item['status'] ?? 'upcoming').toString().toLowerCase();
    final isCompleted = status == 'completed';
    final isCurrent = status == 'current';

    final Color statusColor = isCompleted
        ? const Color(0xFF16A34A)
        : isCurrent
            ? const Color(0xFFF97316)
            : const Color(0xFF64748B);

    final Color nodeBg = isCompleted
        ? const Color(0xFFDCFCE7)
        : isCurrent
            ? const Color(0xFFFFF7ED)
            : const Color(0xFFF1F5F9);

    final IconData statusIcon = isCompleted
        ? Icons.check_rounded
        : isCurrent
            ? Icons.star_rounded
            : Icons.schedule_rounded;

    final cycleNum = item['cycle_number'] ?? 1;
    final totalCycles = item['total_cycles'] ?? 1;
    final recipientName = item['recipient_name'] ?? 'Recipient';
    final projDate = item['projected_date'] ?? 'Upcoming';
    final amount = item['estimated_payout_amount'] ?? 0;
    final numAmount = amount is num ? amount.toDouble() : double.tryParse('$amount') ?? 0.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator line + circle node
        SizedBox(
          width: 36,
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: nodeBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: statusColor,
                    width: isCurrent ? 2.5 : 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(statusIcon, color: statusColor, size: 16),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 120,
                  color: isCompleted ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Payout Card
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCurrent
                          ? const Color(0xFFF97316)
                          : isCompleted
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFE2E8F0),
                      width: isCurrent ? 2.0 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isCurrent
                            ? const Color(0xFFF97316).withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.03),
                        blurRadius: isCurrent ? 10 : 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: nodeBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Round #$cycleNum • Cycle $cycleNum of $totalCycles',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: statusColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: nodeBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isCompleted
                                  ? 'PAID OUT'
                                  : isCurrent
                                      ? 'ACTIVE WINNER'
                                      : 'SCHEDULED',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: nodeBg,
                            child: Text(
                              recipientName.isNotEmpty ? recipientName[0].toUpperCase() : 'M',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
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
                                  'Payout Date: $projDate',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11.5,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'ETB ${numAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: isCompleted ? const Color(0xFF16A34A) : const Color(0xFF111827),
                                ),
                              ),
                              const Row(
                                children: [
                                  Text(
                                    'Details',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: Color(0xFFF97316),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFFF97316)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
  }
}
