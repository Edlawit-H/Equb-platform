import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../groups/presentation/pages/group_detail_page.dart';
import 'widgets/join_group_dialog.dart';

class ActiveGroupDashboard extends StatelessWidget {
  final Map<String, dynamic>? userProfile;
  final List<Map<String, dynamic>> groups;
  final VoidCallback? onRefresh;
  final VoidCallback? onSeeAll;

  const ActiveGroupDashboard({
    super.key,
    this.userProfile,
    required this.groups,
    this.onRefresh,
    this.onSeeAll,
  });

  static const Color primaryOrange = Color(0xFFFF5C00);
  static const Color headerOrange = Color(0xFFFF5C00);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  void _showJoinModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const JoinGroupDialog(),
    );
  }

  void _showPayModal(BuildContext context, {String title = "Pay Contribution", int amount = 1000}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Amount Due: ETB $amount",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryOrange,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Payment of ETB $amount processed successfully!"),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Confirm Payment",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String userName = userProfile?["full_name"] ?? "John Doe";

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
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
                // Top Header Card
                _buildHeaderCard(context, userName),

                const SizedBox(height: 24),

                // Quick Actions (Create Group, Join Group, Pay Contribution)
                _buildQuickActions(context),

                const SizedBox(height: 28),

                // Active Groups Section
                _buildActiveGroupsSection(context),

                const SizedBox(height: 28),

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

  /// Top Orange Curved Header & Balance Card
  Widget _buildHeaderCard(BuildContext context, String userName) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: headerOrange,
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
              // User Profile Top Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Avatar
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
                          child: Container(
                            color: const Color(0xFFE2E8F0),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF64748B),
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  // Notification icon
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.notifications_active_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("No new notifications"),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Total Balance Label
              Text(
                "Total Balance",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),

              // Main Balance Value: ETB 12,500.00
              RichText(
                text: const TextSpan(
                  text: "ETB ",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                  children: [
                    TextSpan(
                      text: "12,500",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    TextSpan(
                      text: ".00",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Thin Divider
              Container(
                height: 1,
                width: double.infinity,
                color: Colors.white.withValues(alpha: 0.25),
              ),

              const SizedBox(height: 16),

              // Sub Stats Row (Total Savings & Active Loans)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Savings",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "ETB 8,500",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Active Loans",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "ETB 0.00",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
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
              final res = await Navigator.pushNamed(context, '/create');
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
            onTap: () => _showPayModal(context),
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
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
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
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textDark,
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
              const Text(
                "Active Groups",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              GestureDetector(
                onTap: onSeeAll ?? () => Navigator.pushNamed(context, '/groups'),
                child: const Text(
                  "See All >",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primaryOrange,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Horizontal Carousel
        SizedBox(
          height: 175,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              // Card 1: Friends Equb
              _buildGroupCard(
                context: context,
                title: "Friends Equb",
                amountText: "ETB 1,000 / Month",
                icon: Icons.people_alt_rounded,
                iconBgColor: const Color(0xFFFDEEE9),
                iconColor: primaryOrange,
                badgeText: "ACTIVE",
                payoutText: "You (Round 3)",
                memberCountText: "+5",
              ),

              const SizedBox(width: 14),

              // Card 2: Family Equb
              _buildGroupCard(
                context: context,
                title: "Family Equb",
                amountText: "ETB 5,000 / Month",
                icon: Icons.home_rounded,
                iconBgColor: const Color(0xFFE6F7F0),
                iconColor: const Color(0xFF0D9488),
                badgeText: "ACTIVE",
                payoutText: "Round 5",
                memberCountText: "+2",
              ),

              // Dynamic groups from API if available
              ...groups.map((group) {
                return Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: _buildGroupCard(
                    context: context,
                    title: group["group_name"] ?? "My Equb",
                    amountText: "ETB ${group["contribution_amount"]} / Month",
                    icon: Icons.groups_rounded,
                    iconBgColor: const Color(0xFFEFF6FF),
                    iconColor: const Color(0xFF3B82F6),
                    badgeText: "ACTIVE",
                    payoutText: "Cycle 1",
                    memberCountText: "+${group["max_members"] ?? 4}",
                    groupData: group,
                  ),
                );
              }),
            ],
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
    Map<String, dynamic>? groupData,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupDetailsPage(
              group: groupData ?? {
                "title": title,
                "amount": amountText.replaceAll(" / Month", "").replaceAll("ETB ", ""),
                "cycle": payoutText,
              },
            ),
          ),
        );
      },
      child: Container(
        width: 245,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
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
          // Icon and Active Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 42,
                height: 42,
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
                  color: const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Color(0xFF1E8E3E),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
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
                ),
              ),
              const SizedBox(height: 2),
              Text(
                amountText,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Divider
          Container(
            height: 1,
            color: const Color(0xFFF1F5F9),
          ),

          // Bottom Avatars & Next Payout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Avatar Stack
              _buildAvatarStack(memberCountText),

              // Next Payout
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Next Payout",
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      payoutText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  /// Small overlapping avatar circle stack using Stack
  Widget _buildAvatarStack(String extraCountText) {
    return SizedBox(
      width: 64,
      height: 22,
      child: Stack(
        children: [
          Positioned(left: 0, child: _miniAvatar(Colors.blueGrey.shade300)),
          Positioned(left: 13, child: _miniAvatar(Colors.amber.shade300)),
          Positioned(left: 26, child: _miniAvatar(Colors.teal.shade300)),
          Positioned(
            left: 39,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Center(
                child: Text(
                  extraCountText,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniAvatar(Color color) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: const Icon(
        Icons.person,
        size: 14,
        color: Colors.white,
      ),
    );
  }

  /// Upcoming Payments Section
  Widget _buildUpcomingPaymentsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Upcoming Payments",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
          const SizedBox(height: 14),

          // Payment 1: Friends Equb
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
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
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDEEE9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.people_alt_rounded,
                      color: primaryOrange,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Friends Equb",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "Due Tomorrow",
                        style: TextStyle(
                          fontSize: 13,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "ETB 1,000",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _showPayModal(context, title: "Friends Equb Payment", amount: 1000),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: primaryOrange,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          "PAY NOW",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Payment 2: Loan Repayment
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
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
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7F0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Color(0xFF0D9488),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Loan Repayment",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "Due in 5 Days",
                        style: TextStyle(
                          fontSize: 13,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  "ETB 500",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
