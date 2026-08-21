import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../groups/presentation/pages/group_detail_page.dart';
import '../../contributions/data/contributions_service.dart';
import 'widgets/join_group_dialog.dart';

class ActiveGroupDashboard extends StatelessWidget {
  final Map<String, dynamic>? userProfile;
  final Map<String, dynamic>? dashboardData;
  final Map<String, dynamic>? summaryData;
  final List<Map<String, dynamic>> groups;
  final List<Map<String, dynamic>> pendingContributions;
  final VoidCallback? onRefresh;
  final VoidCallback? onSeeAll;

  const ActiveGroupDashboard({
    super.key,
    this.userProfile,
    this.dashboardData,
    this.summaryData,
    required this.groups,
    this.pendingContributions = const [],
    this.onRefresh,
    this.onSeeAll,
  });

  static const Color primaryOrange = Color(0xFFF97316);
  static const Color headerOrange = Color(0xFFEA580C);
  static const Color textDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);

  void _showJoinModal(BuildContext context) async {
    final res = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const JoinGroupDialog(),
    );
    if (res == true && onRefresh != null) {
      onRefresh!();
    }
  }

  void _showPayModal(BuildContext context, {required Map<String, dynamic> contribution}) {
    final amount = contribution['amount'] ?? 0;
    final groupName = contribution['group_name'] ?? 'Equb Circle';
    final contributionId = contribution['contribution_id'];
    final memberId = contribution['member_id'];
    final cycleNumber = contribution['cycle_number'] ?? 1;

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
                "Pay Contribution",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                groupName,
                style: const TextStyle(
                  fontSize: 14,
                  color: textMuted,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryOrange.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Amount to Pay",
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "ETB $amount",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: primaryOrange,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "Cycle $cycleNumber",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
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
                            final gId = contribution['group_id'] ?? contribution['id'];
                            final cycle = contribution['cycle_number'] ?? 1;
                            final cycleNum = cycle is int ? cycle : int.tryParse('$cycle') ?? 1;

                            if (gId != null && gId.toString().isNotEmpty) {
                              await ContributionsService().pay(gId.toString(), cycleNum);
                            } else {
                              Navigator.pop(ctx);
                              Navigator.pushNamed(context, '/contributions');
                              return;
                            }

                            if (!context.mounted) return;
                            Navigator.pop(ctx);
                            if (onRefresh != null) onRefresh!();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Contribution of ETB $amount paid successfully!"),
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
                          "Confirm & Pay from Wallet",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
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
    final String userName = userProfile?["full_name"] ?? "Equb Member";

    final balanceVal = dashboardData?['wallet_balance'] ?? userProfile?['wallet_balance'] ?? summaryData?['wallet_balance'] ?? 0;
    final double balance = (balanceVal is num ? balanceVal.toDouble() : double.tryParse('$balanceVal') ?? 0.0);

    final totalContributedVal = summaryData?['total_contributed'] ?? summaryData?['data']?['total_contributed'] ?? 0;
    final double totalContributed = (totalContributedVal is num ? totalContributedVal.toDouble() : double.tryParse('$totalContributedVal') ?? 0.0);

    // Backend key is total_payouts_received (not total_received)
    final totalReceivedVal = summaryData?['total_payouts_received'] ?? summaryData?['data']?['total_payouts_received'] ?? summaryData?['total_received'] ?? 0;
    final double totalReceived = (totalReceivedVal is num ? totalReceivedVal.toDouble() : double.tryParse('$totalReceivedVal') ?? 0.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            if (onRefresh != null) onRefresh!();
          },
          color: primaryOrange,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header & Wallet Balance Card
                _buildHeaderCard(context, userName, balance, totalContributed, totalReceived),

                const SizedBox(height: 22),

                // Quick Actions (Create Group, Join Group, Pay Contribution)
                _buildQuickActions(context),

                const SizedBox(height: 26),

                // Active Groups Horizontal Carousel
                _buildActiveGroupsSection(context),

                const SizedBox(height: 26),

                // Upcoming Payments Section
                _buildUpcomingPaymentsSection(context),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Top Curved Gradient Header & Balance Summary
  Widget _buildHeaderCard(BuildContext context, String userName, double balance, double totalSavings, double payouts) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFEA580C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryOrange.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top User Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            color: const Color(0xFFFDE8DC),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Color(0xFFEA580C),
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Welcome back,",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Text(
                              userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Notification Icon
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () => Navigator.pushNamed(context, '/notifications'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Wallet Balance
              const Text(
                "Wallet Balance",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "ETB ${balance.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Poppins',
                      letterSpacing: -0.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/wallet/top-up'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, color: primaryOrange, size: 16),
                          SizedBox(width: 4),
                          Text(
                            "Top Up",
                            style: TextStyle(
                              color: primaryOrange,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Divider
              Container(
                height: 1,
                width: double.infinity,
                color: Colors.white.withValues(alpha: 0.2),
              ),

              const SizedBox(height: 14),

              // Sub Stats Row (Total Contributed & Total Payouts Won)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Total Savings",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "ETB ${totalSavings.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "Payouts Received",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "ETB ${payouts.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 3 Quick Action Buttons
  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionButton(
            icon: Icons.add_circle_outline_rounded,
            label: "Create Group",
            onTap: () async {
              final res = await Navigator.pushNamed(context, '/groups/create');
              if (res == true && onRefresh != null) onRefresh!();
            },
          ),
          _buildActionButton(
            icon: Icons.group_add_rounded,
            label: "Join Group",
            onTap: () => _showJoinModal(context),
          ),
          _buildActionButton(
            icon: Icons.payments_outlined,
            label: "Pay\nContribution",
            onTap: () {
              if (pendingContributions.isNotEmpty) {
                _showPayModal(context, contribution: pendingContributions.first);
              } else {
                Navigator.pushNamed(context, '/contributions');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
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
            child: Center(
              child: Icon(
                icon,
                color: primaryOrange,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: textDark,
              fontFamily: 'Poppins',
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Active Groups Section with Horizontal Cards
  Widget _buildActiveGroupsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Active Groups (${groups.length})",
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                  fontFamily: 'Poppins',
                ),
              ),
              GestureDetector(
                onTap: onSeeAll ?? () => Navigator.pushNamed(context, '/groups'),
                child: const Text(
                  "See All >",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: primaryOrange,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Carousel of real groups from DB
        if (groups.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.groups_outlined, size: 36, color: textMuted),
                  const SizedBox(height: 8),
                  const Text(
                    "You haven't joined any groups yet",
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: textDark),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Create or join an Equb circle to start saving.",
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: textMuted),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 175,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final group = groups[i];
                final title = group["group_name"] ?? "Equb Circle";
                final amount = group["contribution_amount"] ?? 0;
                final maxMembers = group["max_members"] ?? 10;
                final cycle = group["current_cycle"] ?? 1;
                final status = (group["status"] ?? "active").toString().toUpperCase();

                return _buildGroupCard(
                  context: context,
                  title: title,
                  amountText: "ETB $amount / Cycle",
                  icon: Icons.groups_rounded,
                  iconBgColor: const Color(0xFFEFF6FF),
                  iconColor: const Color(0xFF2563EB),
                  badgeText: status,
                  payoutText: "Cycle $cycle",
                  memberCountText: "$maxMembers",
                  groupData: group,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildGroupCard({
    required BuildContext context,
    required String title,
    required String amountText,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String badgeText,
    required String payoutText,
    required String memberCountText,
    required Map<String, dynamic> groupData,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupDetailsPage(group: groupData),
          ),
        );
      },
      child: Container(
        width: 245,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon & Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Color(0xFF16A34A),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),

            // Title & Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amountText,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: textMuted,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),

            // Divider
            Container(
              height: 1,
              color: const Color(0xFFF1F5F9),
            ),

            // Bottom
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_outline_rounded, size: 16, color: textMuted),
                    const SizedBox(width: 4),
                    Text(
                      "$memberCountText Members",
                      style: const TextStyle(
                        fontSize: 11,
                        color: textMuted,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                Text(
                  payoutText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: primaryOrange,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Upcoming Payments Section with real contributions
  Widget _buildUpcomingPaymentsSection(BuildContext context) {
    final nextDue = dashboardData?['next_due_contribution'];
    final items = pendingContributions.isNotEmpty
        ? pendingContributions
        : (nextDue != null ? [nextDue] : <Map<String, dynamic>>[]);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Upcoming Payments",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                  fontFamily: 'Poppins',
                ),
              ),
              if (items.isNotEmpty)
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/contributions'),
                  child: const Text(
                    "View All >",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: primaryOrange,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "All caught up! No pending contributions due right now.",
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: textMuted),
                    ),
                  ),
                ],
              ),
            )
          else
            ...items.map((item) {
              final groupName = item['group_name'] ?? 'Equb Circle';
              final amount = item['amount'] ?? 0;
              final dueDate = item['due_date'] ?? 'Soon';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.payments_rounded,
                          color: primaryOrange,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            groupName,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: textDark,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Due: $dueDate",
                            style: const TextStyle(
                              fontSize: 12,
                              color: textMuted,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "ETB $amount",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _showPayModal(context, contribution: item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: primaryOrange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "PAY NOW",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
