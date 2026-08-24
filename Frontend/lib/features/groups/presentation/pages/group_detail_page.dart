import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/group_service.dart';
import '../../../contributions/data/contributions_service.dart';
import '../../../payouts/data/payouts_service.dart';
import '../../../reports/data/reports_service.dart';

class GroupDetailsPage extends StatefulWidget {
  final Map<String, dynamic>? group;

  const GroupDetailsPage({
    super.key,
    this.group,
  });

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _groupService = GroupService();
  final _reportsService = ReportsService();
  final _contributionsService = ContributionsService();
  final _payoutsService = PayoutsService();

  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _activity = [];
  List<Map<String, dynamic>> _contributions = [];
  List<Map<String, dynamic>> _payouts = [];
  Map<String, dynamic> _groupSummary = {};
  Map<String, dynamic> _groupDetails = {};
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
    _tabController = TabController(length: 3, vsync: this);
    _loadDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _groupId => widget.group?["group_id"] ?? widget.group?["id"] ?? "";

  Future<void> _loadDetails() async {
    if (_groupId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final futures = await Future.wait([
        _groupService
            .getGroupById(_groupId)
            .catchError((_) => <String, dynamic>{}),
        _groupService
            .getGroupMembers(_groupId)
            .catchError((_) => <String, dynamic>{}),
        _reportsService
            .getGroupSummary(_groupId)
            .catchError((_) => <String, dynamic>{}),
        _contributionsService
            .getGroupContributions(_groupId)
            .catchError((_) => <String, dynamic>{}),
        _payoutsService
            .getGroupPayouts(_groupId)
            .catchError((_) => <String, dynamic>{}),
      ]);

      final groupRes = futures[0];
      final membersRes = futures[1];
      final summaryRes = futures[2];
      final contributionsRes = futures[3];
      final payoutsRes = futures[4];

      if (mounted) {
        setState(() {
          if (groupRes["data"] is Map) {
            _groupDetails = Map<String, dynamic>.from(groupRes["data"]);
          }
          if (membersRes["data"] != null && membersRes["data"] is List) {
            _members = List<Map<String, dynamic>>.from(membersRes["data"]);
          } else {
            _members = [];
          }
          _groupSummary = summaryRes;
          final contributions = contributionsRes["contributions"] is List
              ? List<Map<String, dynamic>>.from(
                  contributionsRes["contributions"])
              : <Map<String, dynamic>>[];
          final payouts = payoutsRes["payouts"] is List
              ? List<Map<String, dynamic>>.from(payoutsRes["payouts"])
              : <Map<String, dynamic>>[];
          _contributions = contributions;
          _payouts = payouts;
          _activity = [
            ...contributions
                .where((item) => item["status"] == "paid")
                .map((item) => {...item, "activity_type": "contribution"}),
            ...payouts
                .where((item) => item["status"] == "completed")
                .map((item) => {...item, "activity_type": "payout"}),
          ]..sort((a, b) => _activityDate(b).compareTo(_activityDate(a)));
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading group details: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  DateTime _activityDate(Map<String, dynamic> item) {
    final value =
        item["paid_date"] ?? item["payout_date"] ?? item["created_at"];
    return DateTime.tryParse(value?.toString() ?? "") ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  void _showContributionModal(
      BuildContext context, String groupName, dynamic amount) {
    final numAmount =
        amount is num ? amount.toDouble() : double.tryParse('$amount') ?? 0.0;
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
                  border:
                      Border.all(color: primaryOrange.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.account_balance_wallet_rounded,
                        color: primaryOrange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Payment Method",
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                fontFamily: 'Poppins'),
                          ),
                          Text(
                            "Equb Digital Wallet Balance",
                            style: TextStyle(
                                color: textMuted,
                                fontSize: 12,
                                fontFamily: 'Poppins'),
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
                            final currentCycle =
                                _groupDetails["current_cycle"] ??
                                    (_groupSummary["group"] is Map
                                        ? _groupSummary["group"]
                                            ["current_cycle"]
                                        : null) ??
                                    widget.group?["current_cycle"];
                            final cycleNum = currentCycle is int
                                ? currentCycle
                                : int.tryParse('$currentCycle');
                            final payable = _contributions.where((item) {
                              final status = item["status"]?.toString();
                              final itemCycle = int.tryParse(
                                  item["cycle_number"]?.toString() ?? "");
                              return (status == "pending" ||
                                      status == "overdue") &&
                                  (cycleNum == null || itemCycle == cycleNum);
                            }).toList();
                            if (payable.isEmpty) {
                              throw Exception(
                                  "There is no unpaid contribution for the current cycle");
                            }
                            final contribution = payable.first;
                            final contributionCycle = int.tryParse(
                                contribution["cycle_number"]?.toString() ?? "");
                            if (contributionCycle == null) {
                              throw Exception(
                                  "Contribution cycle is unavailable");
                            }
                            await _contributionsService.pay(
                                _groupId, contributionCycle);

                            if (!context.mounted) return;
                            Navigator.pop(ctx);
                            _loadDetails();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    "Contribution of ETB ${numAmount.toStringAsFixed(2)} completed!"),
                                backgroundColor: const Color(0xFF16A34A),
                              ),
                            );
                          } catch (e) {
                            setModalState(() => isPaying = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    e.toString().replaceAll("Exception: ", "")),
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
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "Confirm & Pay",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins'),
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
    final group = {...?widget.group, ..._groupDetails};
    final groupTitle = group["group_name"] ?? group["title"] ?? "Equb Circle";
    final amountVal = group["contribution_amount"] ?? group["amount"] ?? 0;
    final groupAmount = "ETB $amountVal / Cycle";
    final inviteCode = group["invitation_code"] ?? "";

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
                icon: const Icon(Icons.share_rounded,
                    color: Colors.white, size: 20),
                tooltip: "Invitation Code: $inviteCode",
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: inviteCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          "Invitation code '$inviteCode' copied to clipboard!"),
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

                // Custom Tab Bar (Members | Contributions | Loans)
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
  Widget _buildGroupOverviewCard(
      String title, String amount, String inviteCode) {
    final summaryGroup = _groupSummary["group"] is Map
        ? Map<String, dynamic>.from(_groupSummary["group"])
        : <String, dynamic>{};
    final status = (summaryGroup["status"] ??
            _groupDetails["status"] ??
            widget.group?["status"] ??
            "ACTIVE")
        .toString()
        .toUpperCase();

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
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: activeGreenBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: activeGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          if (inviteCode.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.vpn_key_rounded,
                          size: 16, color: primaryOrange),
                      const SizedBox(width: 8),
                      Text(
                        "Code: $inviteCode",
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: textDark),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: inviteCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Code copied!"),
                            duration: Duration(seconds: 1)),
                      );
                    },
                    child: const Text("Copy",
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: primaryOrange)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// TabBar (Members | Contributions | Loans)
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
      return const Center(
        child: Text(
          "No members joined yet",
          style: TextStyle(fontFamily: 'Poppins', color: textMuted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final m = _members[i];
        final name = m["full_name"] ?? m["name"] ?? "Member ${i + 1}";
        final role = (m["role"] ?? "member").toString().toUpperCase();
        final memberId = m["member_id"]?.toString();
        final currentCycle = _groupDetails["current_cycle"] ??
            (_groupSummary["group"] is Map
                ? _groupSummary["group"]["current_cycle"]
                : null) ??
            widget.group?["current_cycle"];
        final isPaid = m["has_paid"] == true ||
            _contributions.any((contribution) =>
                contribution["member_id"]?.toString() == memberId &&
                contribution["status"] == "paid" &&
                (currentCycle == null ||
                    contribution["cycle_number"].toString() ==
                        currentCycle.toString()));
        final hasReceivedPayout = _payouts.any((payout) =>
            payout["member_id"]?.toString() == memberId &&
            payout["status"] == "completed");
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
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      color: primaryOrange),
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
                  color: hasReceivedPayout || isPaid
                      ? activeGreenBg
                      : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hasReceivedPayout
                      ? "PAID OUT"
                      : (isPaid ? "PAID" : "PENDING"),
                  style: TextStyle(
                    color: hasReceivedPayout || isPaid
                        ? activeGreen
                        : primaryOrange,
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
    final financials = _groupSummary["financials"] is Map
        ? Map<String, dynamic>.from(_groupSummary["financials"])
        : _groupSummary;
    final summaryGroup = _groupSummary["group"] is Map
        ? Map<String, dynamic>.from(_groupSummary["group"])
        : _groupSummary;
    final totalCollected = financials["total_collected"] ?? 0;
    final totalPaidOut = financials["total_paid_out"] ?? 0;
    final remainingCycles = summaryGroup["remaining_cycles"] ?? 0;
    final completionPct =
        (summaryGroup["completion_percentage"] ?? 0).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryCard("Total Pool", "ETB $totalCollected",
                    Icons.savings_rounded, const Color(0xFF16A34A)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryCard("Total Paid Out", "ETB $totalPaidOut",
                    Icons.send_rounded, primaryOrange),
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
                    const Text("Cycle Completion",
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    Text("${completionPct.toInt()}%",
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            color: primaryOrange)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: completionPct / 100,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(primaryOrange),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 8),
                Text("Remaining cycles: $remainingCycles",
                    style: const TextStyle(
                        fontFamily: 'Poppins', color: textMuted, fontSize: 12)),
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
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textDark)),
          Text(title,
              style: const TextStyle(
                  fontFamily: 'Poppins', color: textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  /// Activity Tab
  Widget _buildLoansTab() {
    if (_activity.isEmpty) {
      return const Center(
        child: Text("No group activity yet",
            style: TextStyle(fontFamily: 'Poppins', color: textMuted)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _activity.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _activity[index];
        final isPayout = item["activity_type"] == "payout";
        final name = item["member_name"] ?? item["recipient_name"] ?? "Member";
        final cycle = item["cycle_number"] ?? "-";
        final amount = item[isPayout ? "payout_amount" : "amount"] ?? 0;
        final date = _activityDate(item);

        return ListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          leading: CircleAvatar(
            backgroundColor: isPayout ? activeGreenBg : const Color(0xFFFFF7ED),
            child: Icon(
              isPayout ? Icons.call_received_rounded : Icons.payments_rounded,
              color: isPayout ? activeGreen : primaryOrange,
            ),
          ),
          title: Text(
            isPayout ? "Payout received" : "Contribution made",
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 13),
          ),
          subtitle: Text(
            "$name  •  Cycle $cycle\n${date == DateTime.fromMillisecondsSinceEpoch(0) ? "" : "${date.day}/${date.month}/${date.year}"}",
            style: const TextStyle(
                fontFamily: 'Poppins', color: textMuted, fontSize: 12),
          ),
          isThreeLine: true,
          trailing: Text(
            "ETB $amount",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              color: isPayout ? activeGreen : textDark,
            ),
          ),
        );
      },
    );
  }

  /// Fixed Bottom Action Button: "Make Contribution"
  Widget _buildBottomAction(String groupTitle, dynamic amount) {
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
          child: ElevatedButton(
            onPressed: () =>
                _showContributionModal(context, groupTitle, amount),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              "Make Contribution",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
