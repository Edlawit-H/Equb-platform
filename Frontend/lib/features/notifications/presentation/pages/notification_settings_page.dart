import 'package:flutter/material.dart';
import '../../data/notifications_repository.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final NotificationsRepository _repository = NotificationsRepository();

  bool _isLoading = true;
  bool _isSaving = false;

  bool _paymentReminders = true;
  bool _payoutAlerts = true;
  bool _groupActivity = true;

  static const Color primaryOrange = Color(0xFFFF5C00);
  static const Color headerTextDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color pageBg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final res = await _repository.getSettings();
      final data = res['data'] is Map ? res['data'] : res;

      if (mounted) {
        setState(() {
          _paymentReminders = data['payment_reminders'] ?? true;
          _payoutAlerts = data['payout_alerts'] ?? true;
          _groupActivity = data['group_activity'] ?? true;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    setState(() => _isSaving = true);

    try {
      await _repository.updateSettings({
        'payment_reminders':
            key == 'payment_reminders' ? value : _paymentReminders,
        'payout_alerts': key == 'payout_alerts' ? value : _payoutAlerts,
        'group_activity': key == 'group_activity' ? value : _groupActivity,
      });

      if (!mounted) return;
      setState(() {
        if (key == 'payment_reminders') _paymentReminders = value;
        if (key == 'payout_alerts') _payoutAlerts = value;
        if (key == 'group_activity') _groupActivity = value;
        _isSaving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Failed to update setting: ${e.toString().replaceAll("Exception: ", "")}"),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: headerTextDark,
            size: 24,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          "Notification Settings",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: headerTextDark,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: primaryOrange, strokeWidth: 2.5),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Preferences",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          icon: Icons.account_balance_wallet_outlined,
                          iconBg: const Color(0xFFFFEDD5),
                          iconColor: const Color(0xFFEA580C),
                          title: "Payment Reminders",
                          subtitle:
                              "Receive reminders before group contribution deadlines.",
                          value: _paymentReminders,
                          onChanged: (val) =>
                              _updateSetting('payment_reminders', val),
                        ),
                        const Divider(height: 1, indent: 72, endIndent: 16),
                        _buildSwitchTile(
                          icon: Icons.paid_outlined,
                          iconBg: const Color(0xFFDCFCE7),
                          iconColor: const Color(0xFF16A34A),
                          title: "Payout Alerts",
                          subtitle:
                              "Get notified when you receive an Equb payout.",
                          value: _payoutAlerts,
                          onChanged: (val) =>
                              _updateSetting('payout_alerts', val),
                        ),
                        const Divider(height: 1, indent: 72, endIndent: 16),
                        _buildSwitchTile(
                          icon: Icons.groups_rounded,
                          iconBg: const Color(0xFFE0F2FE),
                          iconColor: const Color(0xFF0284C7),
                          title: "Group Activity",
                          subtitle:
                              "Get notified when a member joins your group, the group starts, a contribution is made, or a payout is disbursed.",
                          value: _groupActivity,
                          onChanged: (val) =>
                              _updateSetting('group_activity', val),
                        ),
                      ],
                    ),
                  ),
                  if (_isSaving) ...[
                    const SizedBox(height: 20),
                    const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: primaryOrange,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Saving changes...",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12.5,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 22),
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
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                    color: headerTextDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeTrackColor: primaryOrange,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
