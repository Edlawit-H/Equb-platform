import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/profile_service.dart';
import '../../../../main.dart' show routeObserver;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with RouteAware {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  static const Color primaryOrange = Color(0xFFF97316);
  static const Color textDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final res = await ProfileService.getProfile();
      if (mounted) {
        setState(() {
          _profile = res['data'] ?? res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadProfile();
  }
  @override
  Widget build(BuildContext context) {
    final name = _profile?['full_name'] ?? 'Equb Member';
    final phone = _profile?['phone_number'] ?? '—';
    final email = _profile?['email'] ?? '—';
    final role = (_profile?['role'] ?? 'member').toString();
    final balance = _profile?['wallet_balance'] ?? 0;
    final status = (_profile?['status'] ?? 'active').toString().replaceAll('_', ' ');
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'E';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryOrange))
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: primaryOrange,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Profile',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.settings_rounded, color: Colors.white),
                                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Avatar
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.3),
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: Center(
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                role.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Wallet Balance Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Icon(Icons.account_balance_wallet_rounded, color: primaryOrange, size: 24),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Wallet Balance',
                                  style: TextStyle(fontFamily: 'Poppins', color: textMuted, fontSize: 13),
                                ),
                                Text(
                                  'ETB ${(balance is num ? balance.toDouble() : double.tryParse('$balance') ?? 0.0).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                    color: textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/wallet/top-up'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: primaryOrange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Top Up',
                                style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Info Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Personal Information',
                            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15, color: textDark),
                          ),
                          const SizedBox(height: 16),
                          _infoRow(Icons.person_outline_rounded, 'Full Name', name),
                          const Divider(height: 24),
                          _infoRow(Icons.phone_outlined, 'Phone', phone),
                          const Divider(height: 24),
                          _infoRow(Icons.email_outlined, 'Email', email == 'null' ? '—' : email),
                          const Divider(height: 24),
                          _infoRow(Icons.verified_outlined, 'Status', status.capitalize()),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _actionTile(
                          icon: Icons.edit_outlined,
                          label: 'Edit Profile',
                          onTap: () => Navigator.pushNamed(context, '/profile/edit'),
                        ),
                        const SizedBox(height: 10),
                        _actionTile(
                          icon: Icons.lock_outline_rounded,
                          label: 'Change Password',
                          onTap: () => Navigator.pushNamed(context, '/change-password'),
                        ),
                        const SizedBox(height: 10),
                        _actionTile(
                          icon: Icons.history_rounded,
                          label: 'Transaction History',
                          onTap: () => Navigator.pushNamed(context, '/transactions'),
                        ),
                        const SizedBox(height: 10),
                        _actionTile(
                          icon: Icons.bar_chart_rounded,
                          label: 'My Reports & Analytics',
                          onTap: () => Navigator.pushNamed(context, '/reports'),
                        ),
                        const SizedBox(height: 10),
                        _actionTile(
                          icon: Icons.settings_outlined,
                          label: 'Settings',
                          onTap: () => Navigator.pushNamed(context, '/settings'),
                        ),
                        const SizedBox(height: 10),
                        _actionTile(
                          icon: Icons.logout_rounded,
                          label: 'Logout',
                          iconColor: const Color(0xFFDC2626),
                          textColor: const Color(0xFFDC2626),
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Logout', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
                                content: const Text('Are you sure you want to logout?', style: TextStyle(fontFamily: 'Poppins')),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: textMuted)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Logout', style: TextStyle(fontFamily: 'Poppins', color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) {
                              await const FlutterSecureStorage().deleteAll();
                              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: primaryOrange),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: textMuted)),
            Text(value, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: textDark)),
          ],
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = primaryOrange,
    Color textColor = textDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: textColor,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: textColor.withValues(alpha: 0.4), size: 20),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }
}
