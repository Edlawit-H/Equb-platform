import 'package:flutter/material.dart';
import '../../../groups/presentation/pages/group_detail_page.dart';

class NotificationDetailPage extends StatelessWidget {
  final Map<String, dynamic>? notification;

  const NotificationDetailPage({super.key, this.notification});

  static const Color primaryOrange = Color(0xFFFF5C00);
  static const Color headerTextDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF64748B);
  static const Color metaBg = Color(0xFFF8FAFC);
  static const Color pageBg = Colors.white;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = notification ??
        (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?) ??
        {};

    final title = (data['title'] ?? 'Notification').toString();
    final message = (data['message'] ?? '').toString();
    final type = (data['type'] ?? 'update').toString().toLowerCase();
    final dynamic rawCreatedAt = data['created_at'];

    final timeHeader = _formatTimeHeader(rawCreatedAt);
    final dateTimeFormatted = _formatDateTimeFull(rawCreatedAt);

    // Only extract group if explicitly provided
    final groupId = data['group_id']?.toString();
    final groupName = data['group_name']?.toString() ?? _extractQuotedGroupName(message);

    // Only extract transaction id if explicitly provided
    final trxId = data['transaction_id']?.toString() ?? data['tx_id']?.toString();

    final badgeStyle = _getBadgeStyle(type);
    final isPaymentRelated = type.contains('payment') || type.contains('payout') || type.contains('overdue');

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
          "Notification",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: headerTextDark,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Card with Icon, Title, and Timestamp
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: badgeStyle.bgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                badgeStyle.icon,
                                color: badgeStyle.iconColor,
                                size: 26,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    color: headerTextDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  timeHeader,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                    color: textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Message Content
                    _buildMessageBody(message),

                    const SizedBox(height: 32),

                    // Metadata Details Card (Only real fields)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: metaBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Column(
                        children: [
                          _buildMetaRow(
                            label: "Date & Time",
                            value: dateTimeFormatted,
                          ),
                          if (trxId != null && trxId.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _buildMetaRow(
                              label: "Transaction ID",
                              value: trxId,
                              isBoldValue: true,
                            ),
                          ],
                          if (groupName != null && groupName.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _buildMetaRow(
                              label: "Related Group",
                              value: groupName,
                              isLink: groupId != null,
                              onTap: groupId != null
                                  ? () => _openGroup(context, groupId, groupName)
                                  : null,
                            ),
                          ],
                          const SizedBox(height: 14),
                          _buildMetaRow(
                            label: "Category",
                            value: _formatCategory(type),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Context-aware Bottom Action Buttons
            if (isPaymentRelated || (groupId != null && groupId.isNotEmpty))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPaymentRelated)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/transactions');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryOrange,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "View Transactions",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                    if (groupId != null && groupId.isNotEmpty) ...[
                      if (isPaymentRelated) const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          onPressed: () => _openGroup(context, groupId, groupName ?? 'Group'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: primaryOrange, width: 1.8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "Open Group",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: primaryOrange,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openGroup(BuildContext context, String? groupId, String groupName) {
    if (groupId != null && groupId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GroupDetailsPage(group: {'group_id': groupId, 'group_name': groupName}),
        ),
      );
    } else {
      Navigator.pushNamed(context, '/');
    }
  }

  Widget _buildMessageBody(String message) {
    if (message.isEmpty) {
      return const Text(
        "No details provided for this notification.",
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14.5,
          color: textMuted,
        ),
      );
    }

    return Text(
      message,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: Color(0xFF334155),
        height: 1.6,
      ),
    );
  }

  Widget _buildMetaRow({
    required String label,
    required String value,
    bool isBoldValue = false,
    bool isLink = false,
    VoidCallback? onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            color: textMuted,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13.5,
              fontWeight: (isBoldValue || isLink) ? FontWeight.w700 : FontWeight.w500,
              color: isLink ? primaryOrange : headerTextDark,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimeHeader(dynamic timestamp) {
    if (timestamp == null) return "JUST NOW";
    try {
      final date = timestamp is DateTime ? timestamp : DateTime.parse(timestamp.toString());
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 5) return "JUST NOW";
      if (diff.inMinutes < 60) return "${diff.inMinutes} MINS AGO";
      if (diff.inHours < 24) return "${diff.inHours} HR${diff.inHours > 1 ? 'S' : ''} AGO";
      if (diff.inDays == 1) return "YESTERDAY";
      if (diff.inDays < 7) return "${diff.inDays} DAYS AGO";
      return "${date.day}/${date.month}/${date.year}";
    } catch (_) {
      return "JUST NOW";
    }
  }

  String _formatDateTimeFull(dynamic timestamp) {
    if (timestamp == null) {
      final now = DateTime.now();
      final month = _monthName(now.month);
      final hour = now.hour.toString().padLeft(2, '0');
      final minute = now.minute.toString().padLeft(2, '0');
      return "$month ${now.day}, ${now.year} • $hour:$minute";
    }
    try {
      final date = timestamp is DateTime ? timestamp : DateTime.parse(timestamp.toString());
      final month = _monthName(date.month);
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return "$month ${date.day}, ${date.year} • $hour:$minute";
    } catch (_) {
      return timestamp.toString();
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  String? _extractQuotedGroupName(String message) {
    final matchDouble = RegExp(r'"([^"]+)"').firstMatch(message);
    if (matchDouble != null && matchDouble.group(1) != null) {
      return matchDouble.group(1);
    }
    final matchSingle = RegExp(r"'([^']+)'").firstMatch(message);
    if (matchSingle != null && matchSingle.group(1) != null) {
      return matchSingle.group(1);
    }
    return null;
  }

  String _formatCategory(String type) {
    switch (type) {
      case 'payment_reminder':
        return 'Payment Reminder';
      case 'overdue_alert':
        return 'Overdue Alert';
      case 'payout_received':
        return 'Payout Received';
      case 'group_activity':
        return 'Group Activity';
      case 'group_completed':
        return 'Group Completed';
      case 'security_alert':
        return 'Security Alert';
      default:
        return 'General Update';
    }
  }

  _BadgeStyle _getBadgeStyle(String type) {
    switch (type) {
      case 'payment_received':
      case 'payout_received':
      case 'payment_success':
      case 'success':
        return const _BadgeStyle(
          bgColor: Color(0xFFDCFCE7),
          iconColor: Color(0xFF16A34A),
          icon: Icons.check_circle_outline_rounded,
        );
      case 'payment_reminder':
      case 'overdue_alert':
      case 'payment':
        return const _BadgeStyle(
          bgColor: Color(0xFFFFEDD5),
          iconColor: Color(0xFFEA580C),
          icon: Icons.account_balance_wallet_outlined,
        );
      case 'group_activity':
      case 'group_completed':
      case 'group_update':
      case 'member_joined':
        return const _BadgeStyle(
          bgColor: Color(0xFFDCFCE7),
          iconColor: Color(0xFF16A34A),
          icon: Icons.groups_rounded,
        );
      case 'security_alert':
      case 'alert':
      case 'security':
        return const _BadgeStyle(
          bgColor: Color(0xFFE0F2FE),
          iconColor: Color(0xFF0284C7),
          icon: Icons.shield_outlined,
        );
      default:
        return const _BadgeStyle(
          bgColor: Color(0xFFDCFCE7),
          iconColor: Color(0xFF16A34A),
          icon: Icons.check_circle_outline_rounded,
        );
    }
  }
}

class _BadgeStyle {
  final Color bgColor;
  final Color iconColor;
  final IconData icon;
  const _BadgeStyle({
    required this.bgColor,
    required this.iconColor,
    required this.icon,
  });
}
