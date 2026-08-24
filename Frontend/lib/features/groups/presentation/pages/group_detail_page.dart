import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/group_service.dart';
import '../../../contributions/data/contributions_service.dart';
import '../../../reports/data/reports_service.dart';
import '../../../profile/data/profile_service.dart';

class GroupDetailsPage extends StatefulWidget {
  final Map<String, dynamic>? group;

  const GroupDetailsPage({
    super.key,
    this.group,
  });

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _groupService = GroupService();
  final _reportsService = ReportsService();
  final _contributionsService = ContributionsService();

  Map<String, dynamic> _groupData = {};
  List<Map<String, dynamic>> _members = [];
  Map<String, dynamic> _groupSummary = {};
  String? _currentUserId;
  bool _isLoading = true;

  static const Color headerColor = Color(0xFFEA580C);
  static const Color primaryOrange = Color(0xFFF97316);
  static const Color textDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color activeGreen = Color(0xFF16A34A);
  static const Color activeGreenBg = Color(0xFFDCFCE7);

  @override
  void initState() {
    super.initState();
    _groupData = Map<String, dynamic>.from(widget.group ?? {});
    _tabController = TabController(length: 3, vsync: this);
    _loadDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _groupId =>
      _groupData["group_id"]?.toString() ??
      _groupData["id"]?.toString() ??
      widget.group?["group_id"]?.toString() ??
      widget.group?["id"]?.toString() ??
      "";

  String get _inviteCode =>
      _groupData["invitation_code"]?.toString() ??
      _groupData["invite_code"]?.toString() ??
      _groupData["invitationCode"]?.toString() ??
      _groupData["code"]?.toString() ??
      widget.group?["invitation_code"]?.toString() ??
      widget.group?["invite_code"]?.toString() ??
      widget.group?["invitationCode"]?.toString() ??
      widget.group?["code"]?.toString() ??
      "";

  String get _groupTitle =>
      _groupData["group_name"]?.toString() ??
      _groupData["title"]?.toString() ??
      widget.group?["group_name"]?.toString() ??
      widget.group?["title"]?.toString() ??
      "Equb Circle";

  dynamic get _amountVal =>
      _groupData["contribution_amount"] ??
      _groupData["amount"] ??
      widget.group?["contribution_amount"] ??
      widget.group?["amount"] ??
      0;

  String get _groupStatus =>
      (_groupData["status"] ?? widget.group?["status"] ?? "ACTIVE").toString().toUpperCase();

  int get _maxMembers {
    final val = _groupData["max_members"] ?? widget.group?["max_members"] ?? 0;
    return val is int ? val : int.tryParse('$val') ?? 0;
  }

  bool get _isAdmin {
    final explicitRole = (_groupData["role"] ?? widget.group?["role"])?.toString().toLowerCase();
    if (explicitRole == "admin" || explicitRole == "creator" || explicitRole == "owner") {
      return true;
    }

    final adminId = (_groupData["admin_id"] ?? widget.group?["admin_id"])?.toString();
    if (_currentUserId != null && adminId != null && _currentUserId!.isNotEmpty && adminId.isNotEmpty) {
      if (_currentUserId == adminId) return true;
    }

    if (_currentUserId != null && _currentUserId!.isNotEmpty && _members.isNotEmpty) {
      final myMember = _members.firstWhere(
        (m) => m["user_id"]?.toString() == _currentUserId,
        orElse: () => <String, dynamic>{},
      );
      if (myMember.isNotEmpty && myMember["role"]?.toString().toLowerCase() == "admin") {
        return true;
      }
    }

    return false;
  }

  Future<void> _loadDetails() async {
    if (_groupId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final futures = await Future.wait([
        _groupService.getGroupById(_groupId).catchError((_) => <String, dynamic>{}),
        _groupService.getGroupMembers(_groupId).catchError((_) => <String, dynamic>{}),
        _reportsService.getGroupSummary(_groupId).catchError((_) => <String, dynamic>{}),
        ProfileService.getProfile().catchError((_) => <String, dynamic>{}),
      ]);

      final groupRes = futures[0];
      final membersRes = futures[1];
      final summaryRes = futures[2];
      final profileRes = futures[3];

      if (mounted) {
        setState(() {
          if (profileRes["data"] != null && profileRes["data"] is Map) {
            _currentUserId = profileRes["data"]["user_id"]?.toString();
          } else if (profileRes["user_id"] != null) {
            _currentUserId = profileRes["user_id"]?.toString();
          }

          if (groupRes["data"] != null && groupRes["data"] is Map) {
            _groupData = {
              ..._groupData,
              ...Map<String, dynamic>.from(groupRes["data"]),
            };
          }
          if (membersRes["data"] != null && membersRes["data"] is List) {
            _members = List<Map<String, dynamic>>.from(membersRes["data"]);
          } else {
            _members = [];
          }
          _groupSummary = summaryRes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading group details: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showContributionModal(BuildContext context, String groupName, dynamic amount) {
    final numAmount = amount is num ? amount.toDouble() : double.tryParse('$amount') ?? 0.0;
    bool isPaying = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Contribute to $groupName",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Contribution Amount: ETB ${numAmount.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryOrange,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryOrange.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.account_balance_wallet_rounded, color: primaryOrange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Payment Method",
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'Poppins'),
                          ),
                          Text(
                            "Equb Digital Wallet Balance",
                            style: TextStyle(color: textMuted, fontSize: 12, fontFamily: 'Poppins'),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.check_circle_rounded, color: primaryOrange),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isPaying
                      ? null
                      : () async {
                          setModalState(() => isPaying = true);
                          try {
                            final cycle = widget.group?["current_cycle"] ?? 1;
                            final cycleNum = cycle is int ? cycle : int.tryParse('$cycle') ?? 1;
                            await _contributionsService.pay(_groupId, cycleNum);

                            if (!context.mounted) return;
                            Navigator.pop(ctx);
                            _loadDetails();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Contribution of ETB ${numAmount.toStringAsFixed(2)} completed!"),
                                backgroundColor: const Color(0xFF16A34A),
                              ),
                            );
                          } catch (e) {
                            setModalState(() => isPaying = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString().replaceAll("Exception: ", "")),
                                backgroundColor: const Color(0xFFDC2626),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: isPaying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "Confirm & Pay",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
                        ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupTitle = _groupTitle;
    final amountVal = _amountVal;
    final groupAmount = "ETB $amountVal / Cycle";
    final inviteCode = _inviteCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: headerColor,
          elevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Group Details",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: 'Poppins',
            ),
          ),
          centerTitle: true,
          actions: [
            if (inviteCode.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                tooltip: "Invitation Code: $inviteCode",
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: inviteCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Invitation code '$inviteCode' copied to clipboard!"),
                      backgroundColor: primaryOrange,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryOrange))
          : Column(
              children: [
                // Top Group Overview Card
                _buildGroupOverviewCard(groupTitle, groupAmount, inviteCode),

                // Custom Tab Bar (Members | Contributions | Activity)
                _buildTabBar(),

                // Tab Bar Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMembersTab(),
                      _buildContributionsTab(),
                      _buildLoansTab(),
                    ],
                  ),
                ),

                // Fixed Bottom Action Button: "Make Contribution"
                _buildBottomAction(groupTitle, amountVal),
              ],
            ),
    );
  }

  /// Top Group Overview Card
  Widget _buildGroupOverviewCard(String title, String amount, String inviteCode) {
    final status = _groupStatus;
    final isPending = status == "PENDING";

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(
                    Icons.groups_rounded,
                    color: primaryOrange,
                    size: 26,
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
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      amount,
                      style: const TextStyle(
                        fontSize: 13,
                        color: textMuted,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.people_outline_rounded, size: 14, color: textMuted),
                        const SizedBox(width: 4),
                        Text(
                          "${_members.isNotEmpty ? _members.length : (_groupData["current_members"] ?? _groupData["member_count"] ?? 1)} / ${_maxMembers > 0 ? _maxMembers : 10} Members",
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: textMuted,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending ? const Color(0xFFFFF7ED) : activeGreenBg,
                  borderRadius: BorderRadius.circular(8),
                  border: isPending ? Border.all(color: primaryOrange.withValues(alpha: 0.3)) : null,
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isPending ? primaryOrange : activeGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          if (inviteCode.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryOrange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.vpn_key_rounded,
                      size: 18,
                      color: primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "INVITATION CODE",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: primaryOrange,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        SelectableText(
                          inviteCode,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: 2.0,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: inviteCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Invitation code '$inviteCode' copied!"),
                          backgroundColor: const Color(0xFF16A34A),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryOrange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            "Copy",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// TabBar (Members | Contributions | Activity)
  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: primaryOrange,
        indicatorWeight: 3.0,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: primaryOrange,
        unselectedLabelColor: textMuted,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          fontFamily: 'Poppins',
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
        tabs: [
          Tab(text: "Members (${_members.length})"),
          const Tab(text: "Cycle Info"),
          const Tab(text: "Activity"),
        ],
      ),
    );
  }

  /// Members Tab View
  Widget _buildMembersTab() {
    if (_members.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.group_off_rounded, size: 48, color: textMuted),
              const SizedBox(height: 12),
              const Text(
                "No members joined yet",
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16, color: textDark),
              ),
              if (_inviteCode.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  "Share code '$_inviteCode' to invite members.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Poppins', color: textMuted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _inviteCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Invitation code '$_inviteCode' copied!"),
                        backgroundColor: const Color(0xFF16A34A),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text("Copy Invitation Code"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final hasInviteHeader = _inviteCode.isNotEmpty;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _members.length + (hasInviteHeader ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (hasInviteHeader && index == 0) {
          final slotInfo = _maxMembers > 0
              ? "${_members.length}/$_maxMembers slots filled"
              : "${_members.length} members";
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_add_alt_1_rounded, color: primaryOrange, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Invite Members",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: textDark,
                        ),
                      ),
                      Text(
                        "Code: $_inviteCode • $slotInfo",
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11.5,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _inviteCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Invitation code '$_inviteCode' copied!"),
                        backgroundColor: const Color(0xFF16A34A),
                      ),
                    );
                  },
                  child: const Text(
                    "Copy",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      color: primaryOrange,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final i = hasInviteHeader ? index - 1 : index;
        final m = _members[i];
        final name = m["full_name"] ?? m["name"] ?? "Member ${i + 1}";
        final role = (m["role"] ?? "member").toString().toUpperCase();
        final isPaid = m["has_paid"] == true || m["status"] == "paid";
        final payoutPosition = m["payout_position"] ?? (i + 1);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFFFF7ED),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : "M",
                  style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: primaryOrange),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      "Role: $role • Payout Round: #$payoutPosition",
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: textMuted,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaid ? activeGreenBg : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPaid ? "PAID" : "PENDING",
                  style: TextStyle(
                    color: isPaid ? activeGreen : primaryOrange,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Contributions / Cycle Summary Tab
  Widget _buildContributionsTab() {
    final totalCollected = _groupSummary["total_collected"] ?? 0;
    final totalPaidOut = _groupSummary["total_paid_out"] ?? 0;
    final remainingCycles = _groupSummary["remaining_cycles"] ?? 0;
    final completionPct = (_groupSummary["cycle_completion_percentage"] ?? 0).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryCard("Total Pool", "ETB $totalCollected", Icons.savings_rounded, const Color(0xFF16A34A)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryCard("Total Paid Out", "ETB $totalPaidOut", Icons.send_rounded, primaryOrange),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Cycle Completion", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14)),
                    Text("${completionPct.toInt()}%", style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: primaryOrange)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: completionPct / 100,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(primaryOrange),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 8),
                Text("Remaining cycles: $remainingCycles", style: const TextStyle(fontFamily: 'Poppins', color: textMuted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16, color: textDark)),
          Text(title, style: const TextStyle(fontFamily: 'Poppins', color: textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  /// Activity Tab
  Widget _buildLoansTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 40, color: textMuted),
            SizedBox(height: 8),
            Text("Activity is recorded in real time for every cycle round.", textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins', color: textMuted, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  bool _isStarting = false;

  Future<void> _handleStartGroup() async {
    final memberCount = _members.length;
    if (memberCount < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("At least 2 members are required to start the group."),
          backgroundColor: Color(0xFFEA580C),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.play_circle_fill_rounded, color: primaryOrange),
            SizedBox(width: 8),
            Text(
              "Start Equb Circle",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          "Starting this group will begin Cycle #1 for all $memberCount members and generate initial contribution schedules.\n\nAre you sure you want to start now?",
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13.5, color: textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "Cancel",
              style: TextStyle(fontFamily: 'Poppins', color: textMuted, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              "Start Group",
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isStarting = true);

    try {
      final res = await _groupService.startGroup(_groupId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res["message"] ?? "Group started successfully! Cycle 1 has begun."),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );

      await _loadDetails();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  /// Fixed Bottom Action Button: "Start Group" (Admin only) or "Make Contribution"
  Widget _buildBottomAction(String groupTitle, dynamic amount) {
    final isPending = _groupStatus == "PENDING";
    final isCompleted = _groupStatus == "COMPLETED";

    if (isCompleted) {
      return const SizedBox.shrink();
    }

    if (isPending && !_isAdmin) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Color(0xFFE2E8F0),
              width: 1.0,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_top_rounded, color: primaryOrange, size: 18),
                SizedBox(width: 8),
                Text(
                  "Waiting for admin to start the group",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isStarting
                ? null
                : (isPending
                    ? _handleStartGroup
                    : () => _showContributionModal(context, groupTitle, amount)),
            icon: _isStarting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Icon(
                    isPending ? Icons.play_arrow_rounded : Icons.payments_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
            label: Text(
              isPending
                  ? (_isStarting ? "Starting Group..." : "Start Equb Group")
                  : "Make Contribution",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                fontFamily: 'Poppins',
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }
}

