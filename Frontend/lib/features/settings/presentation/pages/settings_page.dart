import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/theme/app_theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section('Account', [
              _Item(Icons.person_rounded, 'My Profile', AppTheme.primary, () => Navigator.pushNamed(context, '/profile')),
              _Item(Icons.lock_rounded, 'Change Password', AppTheme.primary, () => Navigator.pushNamed(context, '/change-password')),
            ]),
            const SizedBox(height: 16),
            _Section('Preferences', [
              _Item(Icons.language_rounded, 'Language', AppTheme.secondary, () => Navigator.pushNamed(context, '/settings/language')),
              _Item(Icons.notifications_rounded, 'Notification Settings', AppTheme.secondary, () => Navigator.pushNamed(context, '/notifications/settings')),
            ]),
            const SizedBox(height: 16),
            _Section('Security', [
              _Item(Icons.pin_rounded, 'PIN Setup', const Color(0xFF7C3AED), () => Navigator.pushNamed(context, '/settings/pin-setup')),
              _Item(Icons.devices_rounded, 'Active Sessions', const Color(0xFF7C3AED), () => Navigator.pushNamed(context, '/settings/sessions')),
            ]),
            const SizedBox(height: 16),
            _Section('Support', [
              _Item(Icons.help_rounded, 'Help & Support', AppTheme.grayText, () => Navigator.pushNamed(context, '/settings/help')),
              _Item(Icons.info_rounded, 'About Equb', AppTheme.grayText, () => Navigator.pushNamed(context, '/settings/about')),
            ]),
            const SizedBox(height: 16),
            _LogoutButton(),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<_Item> items;
  const _Section(this.title, this.items);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(title, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppTheme.grayText, fontSize: 12, letterSpacing: 0.5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final item = e.value;
              final isLast = e.key == items.length - 1;
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(color: item.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(item.icon, color: item.color, size: 20),
                    ),
                    title: Text(item.label, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, color: AppTheme.darkText, fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.grayText, size: 20),
                    onTap: item.onTap,
                  ),
                  if (!isLast) const Divider(height: 1, indent: 66, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _Item {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Item(this.icon, this.label, this.color, this.onTap);
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => showDialog(context: context, builder: (_) => const _LogoutDialog()),
        icon: const Icon(Icons.logout_rounded, color: AppTheme.error),
        label: const Text('Logout', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppTheme.error, fontSize: 15)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.error),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Logout', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
      content: const Text('Are you sure you want to logout?', style: TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText)),
        ),
        ElevatedButton(
          onPressed: () async {
            const storage = FlutterSecureStorage();
            await storage.deleteAll();
            if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Logout', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

