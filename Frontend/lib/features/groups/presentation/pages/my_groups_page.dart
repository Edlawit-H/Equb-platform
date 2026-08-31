import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './group_detail_page.dart';
import '../../data/group_service.dart';
import '../../../dashboard/presentation/widgets/join_group_dialog.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  int _selectedTabIndex = 0; // 0 for Active, 1 for Completed
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;
  String? _errorMessage;

  static const Color primaryOrange = Color(0xFFF97316);
  static const Color headerOrange = Color(0xFFEA580C);
  static const Color textDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color activeGreen = Color(0xFF16A34A);
  static const Color activeGreenBg = Color(0xFFDCFCE7);
  static const Color borderColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final groupRes = await GroupService().getGroups();

      List<Map<String, dynamic>> groups = [];
      if (groupRes["data"] is List) {
        groups = List<Map<String, dynamic>>.from(groupRes["data"]);
      } else if (groupRes["groups"] is List) {
        groups = List<Map<String, dynamic>>.from(groupRes["groups"]);
      } else if (groupRes is List) {
        groups = List<Map<String, dynamic>>.from(groupRes as dynamic);
      }

      for (var g in groups) {
        final current = g["current_members"] ?? g["member_count"] ?? g["members_count"];
        if (current != null) {
          g["actual_member_count"] = current is num ? current.toInt() : int.tryParse('$current') ?? 1;
        }
      }

      if (mounted) {
        setState(() {
          _groups = groups;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint("Error fetching groups data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll("Exception: ", "");
        });
      }
    }
  }

  void _showGroupDetails(Map<String, dynamic> group) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailsPage(group: group),
      ),
    );
    if (updated == true) {
      _loadData();
    }
  }

  void _showJoinDialog() async {
    final res = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const JoinGroupDialog(),
    );
    if (res == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeGroups = _groups
        .where((g) => (g["status"] ?? "").toString().toLowerCase() != "completed")
        .toList();
    final completedGroups = _groups
        .where((g) => (g["status"] ?? "").toString().toLowerCase() == "completed")
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          backgroundColor: headerOrange,
          elevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          titleSpacing: 20,
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.8),
                  color: const Color(0xFFFFF7ED),
                ),
                child: const Center(
                  child: Icon(
                    Icons.groups_rounded,
                    color: headerOrange,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "My Equbs",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: Colors.white,
                size: 24,
              ),
              tooltip: "Join Group with Code",
              onPressed: _showJoinDialog,
            ),
            IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 24,
              ),
              tooltip: "Refresh",
              onPressed: _loadData,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryOrange),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: primaryOrange,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                children: [
                  // Error Banner if network/API failed
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: Color(0xFF991B1B),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _loadData,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              "Retry",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFDC2626),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Header title with total count badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Equb Circles",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryOrange.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          "${_groups.length} Total",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: headerOrange,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Segmented Switcher (Active / Completed)
                  _buildSegmentedSwitcher(activeGroups.length, completedGroups.length),

                  const SizedBox(height: 20),

                  // Active or Completed Groups
                  if (_selectedTabIndex == 0)
                    ..._buildActiveTab(activeGroups)
                  else
                    ..._buildCompletedTab(completedGroups),

                  const SizedBox(height: 24),

                  // Dashed "Create New Group" Button
                  _buildDashedCreateButton(),

                  const SizedBox(height: 14),

                  // Secondary "Join Group with Code" Button
                  _buildJoinWithCodeButton(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  /// Segmented Switcher (Active / Completed) with counts
  Widget _buildSegmentedSwitcher(int activeCount, int completedCount) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Active Tab
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 0),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _selectedTabIndex == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Active",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: _selectedTabIndex == 0 ? FontWeight.w700 : FontWeight.w500,
                          color: _selectedTabIndex == 0 ? headerOrange : textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 0 ? const Color(0xFFFFF7ED) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "$activeCount",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _selectedTabIndex == 0 ? headerOrange : textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Completed Tab
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 1),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _selectedTabIndex == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Completed",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: _selectedTabIndex == 1 ? FontWeight.w700 : FontWeight.w500,
                          color: _selectedTabIndex == 1 ? headerOrange : textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 1 ? const Color(0xFFFFF7ED) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "$completedCount",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _selectedTabIndex == 1 ? headerOrange : textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Active Groups List
  List<Widget> _buildActiveTab(List<Map<String, dynamic>> activeGroups) {
    if (activeGroups.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
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
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.groups_outlined,
                    size: 32,
                    color: headerOrange,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "No active Equbs yet",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Join an existing savings circle with an invitation code or create your own circle to get started.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: textMuted,
                  fontFamily: 'Poppins',
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showJoinDialog,
                      icon: const Icon(Icons.vpn_key_rounded, size: 16),
                      label: const Text("Join Code", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: headerOrange,
                        side: const BorderSide(color: headerOrange),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final res = await Navigator.pushNamed(context, '/groups/create');
                        if (res == true) _loadData();
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text("Create Equb", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ];
    }

    final List<Widget> cardWidgets = [];
    for (int i = 0; i < activeGroups.length; i++) {
      final g = activeGroups[i];
      final currentMembers = g["actual_member_count"] ?? g["current_members"] ?? g["member_count"] ?? g["members_count"] ?? 1;
      final maxMembers = g["max_members"] ?? 10;
      final status = (g["status"] ?? "pending").toString().toUpperCase();
      final isPending = status == "PENDING";

      if (i > 0) cardWidgets.add(const SizedBox(height: 16));
      cardWidgets.add(
        _buildGroupCard(
          title: g["group_name"] ?? "Equb Group",
          membersText: "$currentMembers / $maxMembers Members",
          amountText: "ETB ${g["contribution_amount"] ?? 0}",
          periodText: " / Cycle",
          cycleText: isPending
              ? "Pending Start"
              : "Cycle ${g["current_cycle"] ?? 1}/${g["total_cycles"] ?? maxMembers}",
          payoutText: "Status: $status",
          statusText: status,
          isPending: isPending,
          icon: Icons.groups_rounded,
          onDetails: () => _showGroupDetails(g),
        ),
      );
    }

    return cardWidgets;
  }

  /// Completed Tab View
  List<Widget> _buildCompletedTab(List<Map<String, dynamic>> completedGroups) {
    if (completedGroups.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
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
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    size: 32,
                    color: textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "No completed Equbs yet",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "When your savings circles finish all cycles and payouts, they will be archived here.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: textMuted,
                  fontFamily: 'Poppins',
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    final List<Widget> cardWidgets = [];
    for (int i = 0; i < completedGroups.length; i++) {
      final g = completedGroups[i];
      final currentMembers = g["actual_member_count"] ?? g["current_members"] ?? g["member_count"] ?? g["members_count"] ?? 1;
      final maxMembers = g["max_members"] ?? 10;
      if (i > 0) cardWidgets.add(const SizedBox(height: 16));
      cardWidgets.add(
        _buildGroupCard(
          title: g["group_name"] ?? "Equb Group",
          membersText: "$currentMembers / $maxMembers Members",
          amountText: "ETB ${g["contribution_amount"] ?? 0}",
          periodText: " / Cycle",
          cycleText: "Completed",
          payoutText: "All cycles paid out",
          statusText: "COMPLETED",
          isPending: false,
          icon: Icons.check_circle_rounded,
          onDetails: () => _showGroupDetails(g),
        ),
      );
    }
    return cardWidgets;
  }

  /// Single Group Card matching design system
  Widget _buildGroupCard({
    required String title,
    required String membersText,
    required String amountText,
    required String periodText,
    required String cycleText,
    required String payoutText,
    required String statusText,
    required bool isPending,
    required IconData icon,
    required VoidCallback onDetails,
  }) {
    final bool isCompleted = statusText == "COMPLETED";
    final Color statusBg = isCompleted
        ? const Color(0xFFF1F5F9)
        : (isPending ? const Color(0xFFFFF7ED) : activeGreenBg);
    final Color statusColor = isCompleted
        ? textMuted
        : (isPending ? headerOrange : activeGreen);
    final Border? statusBorder = isPending
        ? Border.all(color: headerOrange.withValues(alpha: 0.3))
        : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row (Icon, Title/Members, Status Badge)
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCompleted ? const Color(0xFFE2E8F0) : primaryOrange.withValues(alpha: 0.2),
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: isCompleted ? textMuted : headerOrange,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                        fontFamily: 'Poppins',
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      membersText,
                      style: const TextStyle(
                        fontSize: 13,
                        color: textMuted,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(14),
                  border: statusBorder,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      color: statusColor,
                      size: 7,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Inner Grey Box (Contribution & Status/Timeline)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Contribution
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "CONTRIBUTION",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          amountText,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                          ),
                        ),
                        Text(
                          periodText,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Status / Timeline
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "TIMELINE",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cycleText,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isCompleted
                            ? textMuted
                            : (isPending ? headerOrange : activeGreen),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Dotted Divider
          CustomPaint(
            size: const Size(double.infinity, 1),
            painter: DottedLinePainter(),
          ),

          const SizedBox(height: 12),

          // Bottom Row (Payout Date & Details Link)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    payoutText,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.5,
                      color: textMuted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onDetails,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Details",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: headerOrange,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: headerOrange,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Dashed "Create New Group" Container Button
  Widget _buildDashedCreateButton() {
    return GestureDetector(
      onTap: () async {
        final res = await Navigator.pushNamed(context, '/groups/create');
        if (res == true) {
          _loadData();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter: DashedRectPainter(
          color: primaryOrange,
          strokeWidth: 1.5,
          gap: 4,
          dash: 6,
          radius: 20,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primaryOrange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.add_rounded,
                    color: headerOrange,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Create New Equb Group",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: headerOrange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Secondary "Join Group with Code" Button
  Widget _buildJoinWithCodeButton() {
    return OutlinedButton.icon(
      onPressed: _showJoinDialog,
      icon: const Icon(Icons.vpn_key_rounded, size: 18, color: headerOrange),
      label: const Text(
        "Join Group with Invitation Code",
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: headerOrange,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFFED7AA), width: 1.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
    );
  }
}

/// Dotted horizontal divider line painter
class DottedLinePainter extends CustomPainter {
  final Color color;
  final double dotRadius;
  final double spacing;

  DottedLinePainter({
    this.color = const Color(0xFFE2E8F0),
    this.dotRadius = 1.0,
    this.spacing = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawCircle(Offset(startX, size.height / 2), dotRadius, paint);
      startX += spacing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Dashed rounded rectangle border painter
class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double radius;

  DashedRectPainter({
    this.color = const Color(0xFFF97316),
    this.strokeWidth = 1.5,
    this.gap = 4.0,
    this.dash = 6.0,
    this.radius = 20.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double length =
            (distance + dash < metric.length) ? dash : metric.length - distance;
        dashPath.addPath(
          metric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += dash + gap;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dash != dash ||
        oldDelegate.radius != radius;
  }
}
