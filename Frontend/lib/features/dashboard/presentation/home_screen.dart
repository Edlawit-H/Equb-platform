import 'package:flutter/material.dart';
import '../../groups/data/group_service.dart';
import '../../groups/presentation/pages/my_groups_page.dart';
import '../../profile/presentation/pages/profile_page.dart';
import '../../profile/data/profile_service.dart';
import '../../wallet/presentation/pages/wallet_page.dart';
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
      ]);

      final groupRes = futures[0];
      final profileRes = futures[1];

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

  void _showPayModal() {
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
            const Text(
              "Quick Pay",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Select a group to pay your periodic contribution:",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              leading: const Icon(Icons.people_alt_rounded, color: Color(0xFFFF5C00)),
              title: const Text("Friends Equb", style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text("Due: ETB 1,000"),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Payment of ETB 1,000 completed!"),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5C00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Pay"),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAFAFA),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF5C00),
          ),
        ),
      );
    }

    // When there are no existing groups -> Empty Group State Dashboard
    if (_groups.isEmpty) {
      return EmptyGroupDashboard(
        onRefresh: loadDashboardData,
      );
    }

    // When there is an existing group -> Active Group State Dashboard
    return ActiveGroupDashboard(
      userProfile: _userProfile,
      groups: _groups,
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
        index: _currentIndex == 2 ? 0 : (_currentIndex > 2 ? _currentIndex - 1 : _currentIndex),
        children: [
          _buildHomeTab(),
          const GroupsPage(),
          const WalletPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            // Center Pay button tapped
            _showPayModal();
          } else {
            setState(() {
              _currentIndex = index;
            });
            if (index == 0) {
              loadDashboardData();
            }
          }
        },
      ),
    );
  }
}