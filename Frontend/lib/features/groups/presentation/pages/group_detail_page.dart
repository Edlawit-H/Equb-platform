import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  static const Color headerColor = Color(0xFF9E3A00);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color primaryOrange = Color(0xFFFF5C00);
  static const Color activeGreen = Color(0xFF16A34A);
  static const Color activeGreenBg = Color(0xFFDCFCE7);
  static const Color pendingOrange = Color(0xFFC2410C);
  static const Color pendingOrangeBg = Color(0xFFFEE8DC);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showContributionModal(BuildContext context, String groupName, String amount) {
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
              "Contribute to $groupName",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Due Contribution Amount: $amount",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: headerColor,
              ),
            ),
            const SizedBox(height: 20),
            // Payment method selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
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
                          "Equb Digital Wallet",
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        Text(
                          "Balance: ETB 12,500.00",
                          style: TextStyle(color: textMuted, fontSize: 12),
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
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Contribution of $amount completed successfully!"),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: headerColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Confirm & Pay",
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
    final groupTitle = widget.group?["title"] ?? widget.group?["group_name"] ?? "Friends Equb";
    final groupAmount = widget.group?["amount"] != null
        ? "ETB ${widget.group!["amount"]} / Month"
        : (widget.group?["contribution_amount"] != null
            ? "ETB ${widget.group!["contribution_amount"]} / Month"
            : "ETB 1,000 / Month");

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
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
              fontSize: 19,
              letterSpacing: 0.2,
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: Column(
        children: [
          // Top Group Overview Card
          _buildGroupOverviewCard(groupTitle, groupAmount),

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
          _buildBottomAction(groupTitle, groupAmount.split(" / ")[0]),
        ],
      ),
    );
  }

  /// Top Group Overview Card
  Widget _buildGroupOverviewCard(String title, String amount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          // Peach Icon Container
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFDE8DC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.people_alt_rounded,
                color: headerColor,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Title & Amount
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 14,
                    color: textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // ACTIVE Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: activeGreenBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "ACTIVE",
              style: TextStyle(
                color: activeGreen,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
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
        indicatorColor: headerColor,
        indicatorWeight: 3.0,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: headerColor,
        unselectedLabelColor: textMuted,
        labelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: "Members"),
          Tab(text: "Contributions"),
          Tab(text: "Loans"),
        ],
      ),
    );
  }

  /// Members Tab View
  Widget _buildMembersTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        _buildMemberCard(
          name: "Sara Ahmed",
          amount: "ETB 1,000",
          isPaid: true,
          avatarUrl: null,
          initial: null,
        ),
        const SizedBox(height: 12),
        _buildMemberCard(
          name: "Dawit Tadesse",
          amount: "ETB 1,000",
          isPaid: false,
          avatarUrl: null,
          initial: null,
        ),
        const SizedBox(height: 12),
        _buildMemberCard(
          name: "Alemayehu G.",
          amount: "ETB 1,000",
          isPaid: true,
          avatarUrl: null,
          initial: "A",
          initialColor: primaryOrange,
        ),
        const SizedBox(height: 12),
        _buildMemberCard(
          name: "Betelhem M.",
          amount: "ETB 1,000",
          isPaid: false,
          avatarUrl: null,
          initial: null,
        ),
      ],
    );
  }

  /// Member Card Widget matching the design
  Widget _buildMemberCard({
    required String name,
    required String amount,
    required bool isPaid,
    String? avatarUrl,
    String? initial,
    Color initialColor = primaryOrange,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          if (initial != null)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: initialColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF1F5F9),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF64748B),
                  size: 26,
                ),
              ),
            ),
          const SizedBox(width: 14),
          // Name and Amount
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 13,
                    color: textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Status Badge (PAID / PENDING)
          if (isPaid)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: activeGreenBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: activeGreen,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    "PAID",
                    style: TextStyle(
                      color: activeGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: pendingOrangeBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: pendingOrange,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    "PENDING",
                    style: TextStyle(
                      color: pendingOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Contributions Tab View
  Widget _buildContributionsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Summary Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Cycle Progress",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textDark),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total Pool: ETB 12,000", style: TextStyle(fontWeight: FontWeight.w700, color: headerColor)),
                  Text("Round 4 of 12", style: TextStyle(color: textMuted, fontWeight: FontWeight.w600)),
                ],
              ),
              SizedBox(height: 12),
              LinearProgressIndicator(
                value: 4 / 12,
                color: headerColor,
                backgroundColor: Color(0xFFF1F5F9),
                minHeight: 8,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Contribution History",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textDark),
        ),
        const SizedBox(height: 12),
        _historyItem("Round 3", "Payout recipient: Sara Ahmed", "ETB 12,000", true),
        _historyItem("Round 2", "Payout recipient: Dawit Tadesse", "ETB 12,000", true),
        _historyItem("Round 1", "Payout recipient: Alemayehu G.", "ETB 12,000", true),
      ],
    );
  }

  Widget _historyItem(String round, String subtitle, String amount, bool completed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: activeGreenBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_rounded, color: activeGreen, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(round, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(color: textMuted, fontSize: 12)),
                ],
              ),
            ],
          ),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: textDark)),
        ],
      ),
    );
  }

  /// Loans Tab View
  Widget _buildLoansTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Group Emergency Loan Pool",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                "Members can request an emergency loan of up to 50% of total savings.",
                style: TextStyle(color: textMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Available Pool Funds:", style: TextStyle(color: textMuted, fontWeight: FontWeight.w600)),
                  Text("ETB 6,000.00", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: headerColor)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Loan request submitted for group review")),
                    );
                  },
                  icon: const Icon(Icons.request_quote_rounded, color: headerColor),
                  label: const Text("Request Emergency Loan", style: TextStyle(color: headerColor, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: headerColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Fixed Bottom Action Button: "Make Contribution"
  Widget _buildBottomAction(String groupName, String amount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFF1F5F9),
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => _showContributionModal(context, groupName, amount),
            style: ElevatedButton.styleFrom(
              backgroundColor: headerColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.payments_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 10),
                Text(
                  "Make Contribution",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

