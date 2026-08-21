import 'package:flutter/material.dart';
import '../../groups/data/group_service.dart';
import '../../groups/presentation/pages/my_groups_page.dart';
import '../../profile/presentation/pages/profile_page.dart';
import '../../profile/data/profile_service.dart';
import '../../wallet/presentation/pages/wallet_page.dart';
import '../../contributions/presentation/pages/contribution_list_page.dart';
import '../../contributions/data/contributions_service.dart';
import '../../reports/data/reports_service.dart';
import 'active_group_dashboard.dart';
import 'empty_group_dashboard.dart';
import 'widgets/custom_bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _groups = [];
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _summaryData;
  List<Map<String, dynamic>> _pendingContributions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final futures = await Future.wait([
        GroupService().getGroups().catchError((_) => <String, dynamic>{}),
        ProfileService.getProfile().catchError((_) => <String, dynamic>{}),
        ReportsService().getDashboard().catchError((_) => <String, dynamic>{}),
        ReportsService().getUserSummary().catchError((_) => <String, dynamic>{}),
        ContributionsService().getPendingContributions().catchError((_) => <Map<String, dynamic>>[]),
      ]);

      final groupRes = futures[0] as Map<String, dynamic>;
      final profileRes = futures[1] as Map<String, dynamic>;
      final dashboardRes = futures[2] as Map<String, dynamic>;
      final summaryRes = futures[3] as Map<String, dynamic>;
      final pendingRes = futures[4] as List<Map<String, dynamic>>;

      if (mounted) {
        setState(() {
          if (groupRes["data"] != null && groupRes["data"] is List) {
            _groups = List<Map<String, dynamic>>.from(groupRes["data"]);
          } else {
            _groups = [];
          }

          if (profileRes["data"] != null && profileRes["data"] is Map) {
            _userProfile = Map<String, dynamic>.from(profileRes["data"]);
          }

          _dashboardData = dashboardRes.isNotEmpty
              ? (dashboardRes['data'] ?? dashboardRes)
              : null;
          _summaryData = summaryRes.isNotEmpty
              ? (summaryRes['data'] ?? summaryRes)
              : null;
          _pendingContributions = pendingRes;

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading dashboard data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildHomeTab() {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FAFB),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFF97316),
          ),
        ),
      );
    }

    if (_groups.isEmpty) {
      return EmptyGroupDashboard(
        onRefresh: loadDashboardData,
      );
    }

    return ActiveGroupDashboard(
      userProfile: _userProfile,
      dashboardData: _dashboardData,
      summaryData: _summaryData,
      groups: _groups,
      pendingContributions: _pendingContributions,
      onRefresh: loadDashboardData,
      onSeeAll: () {
        setState(() {
          _currentIndex = 1; // Switch to Groups tab
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          const GroupsPage(),
          const ContributionListPage(),
          const WalletPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) {
            loadDashboardData();
          }
        },
      ),
    );
  }
}