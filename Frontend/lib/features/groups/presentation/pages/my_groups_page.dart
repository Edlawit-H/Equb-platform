import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './group_detail_page.dart';
import '../../data/group_service.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  int _selectedTabIndex = 0; // 0 for Active, 1 for Completed
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;

  static const Color headerColor = Color(0xFF9E3A00);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color primaryBrown = Color(0xFF8D3606);
  static const Color activeGreen = Color(0xFF16A34A);
  static const Color activeGreenBg = Color(0xFFDCFCE7);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final groupRes = await GroupService().getGroups().catchError((_) => <String, dynamic>{});

      if (mounted) {
        setState(() {
          if (groupRes["data"] != null && groupRes["data"] is List) {
            _groups = List<Map<String, dynamic>>.from(groupRes["data"]);
          } else {
            _groups = [];
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching groups data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showGroupDetails(Map<String, dynamic> group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailsPage(group: group),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          automaticallyImplyLeading: false,
          titleSpacing: 16,
          title: Row(
            children: [
              // User Avatar
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.8),
                  color: const Color(0xFFFDE8DC),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: Container(
                    color: const Color(0xFFE2E8F0),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF64748B),
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "EQUb",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 26,
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
            const SizedBox(width: 8),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: headerColor),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: headerColor,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                children: [
                  // "My Groups" Title
                  const Text(
                    "My Groups",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Segmented Switcher (Active / Completed)
                  _buildSegmentedSwitcher(),

                  const SizedBox(height: 22),

                  // Active or Completed Groups
                  if (_selectedTabIndex == 0) ..._buildActiveTab() else ..._buildCompletedTab(),

                  const SizedBox(height: 24),

                  // Dashed "Create New Group" Button
                  _buildDashedCreateButton(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  /// Segmented Switcher (Active / Completed)
  Widget _buildSegmentedSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
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
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    "Active",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: _selectedTabIndex == 0 ? FontWeight.w700 : FontWeight.w500,
                      color: _selectedTabIndex == 0 ? primaryBrown : textMuted,
                    ),
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
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    "Completed",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: _selectedTabIndex == 1 ? FontWeight.w700 : FontWeight.w500,
                      color: _selectedTabIndex == 1 ? primaryBrown : textMuted,
                    ),
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
  List<Widget> _buildActiveTab() {
    final List<Widget> cardWidgets = [];

    // Group 1: Tech Gadgets Equb
    cardWidgets.add(
      _buildGroupCard(
        title: "Tech Gadgets Equb",
        membersText: "12 Members",
        amountText: "ETB 1,000",
        periodText: " / Mo",
        cycleText: "Cycle 4/12",
        payoutText: "Next payout in 5 days",
        icon: Icons.devices_other_rounded,
        onDetails: () => _showGroupDetails({
          "title": "Tech Gadgets Equb",
          "amount": "1,000",
          "members": 12,
          "cycle": "Cycle 4/12",
          "payout": "Next payout in 5 days",
        }),
      ),
    );

    cardWidgets.add(const SizedBox(height: 18));

    // Group 2: Family Savings
    cardWidgets.add(
      _buildGroupCard(
        title: "Family Savings",
        membersText: "8 Members",
        amountText: "ETB 5,000",
        periodText: " / Mo",
        cycleText: "Cycle 2/8",
        payoutText: "Next payout in 14 days",
        icon: Icons.home_outlined,
        onDetails: () => _showGroupDetails({
          "title": "Family Savings",
          "amount": "5,000",
          "members": 8,
          "cycle": "Cycle 2/8",
          "payout": "Next payout in 14 days",
        }),
      ),
    );

    // Any dynamic groups from API
    for (final g in _groups) {
      cardWidgets.add(const SizedBox(height: 18));
      cardWidgets.add(
        _buildGroupCard(
          title: g["group_name"] ?? "Equb Group",
          membersText: "${g["max_members"] ?? 10} Members",
          amountText: "ETB ${g["contribution_amount"] ?? 1000}",
          periodText: " / Mo",
          cycleText: "Cycle 1/${g["cycle_duration"] ?? 12}",
          payoutText: "Next payout in 30 days",
          icon: Icons.group_work_outlined,
          onDetails: () => _showGroupDetails(g),
        ),
      );
    }

    return cardWidgets;
  }

  /// Completed Tab View
  List<Widget> _buildCompletedTab() {
    return [
      Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
              SizedBox(height: 12),
              Text(
                "No completed Equbs yet",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Completed savings cycles will appear here.",
                style: TextStyle(
                  fontSize: 13,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  /// Single Group Card matching design
  Widget _buildGroupCard({
    required String title,
    required String membersText,
    required String amountText,
    required String periodText,
    required String cycleText,
    required String payoutText,
    required IconData icon,
    required VoidCallback onDetails,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row (Icon, Title/Members, Active Badge)
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF1EB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: primaryBrown,
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
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      membersText,
                      style: const TextStyle(
                        fontSize: 13,
                        color: textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Active Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: activeGreenBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      color: activeGreen,
                      size: 7,
                    ),
                    SizedBox(width: 5),
                    Text(
                      "Active",
                      style: TextStyle(
                        color: activeGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Inner Grey Box (Contribution & Status)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
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
                        fontSize: 11,
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
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                          ),
                        ),
                        Text(
                          periodText,
                          style: const TextStyle(
                            fontSize: 13,
                            color: textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "STATUS",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cycleText,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: primaryBrown,
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
                      fontSize: 13,
                      color: textMuted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onDetails,
                child: const Text(
                  "Details",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primaryBrown,
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
        final res = await Navigator.pushNamed(context, '/create');
        if (res == true) {
          _loadData();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter: DashedRectPainter(
          color: primaryBrown,
          strokeWidth: 1.5,
          gap: 4,
          dash: 6,
          radius: 20,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFBF9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDE8DC),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.add,
                    color: primaryBrown,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Create New Group",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: primaryBrown,
                ),
              ),
            ],
          ),
        ),
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
    this.color = const Color(0xFF8D3606),
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
        final double length = (distance + dash < metric.length) ? dash : metric.length - distance;
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

