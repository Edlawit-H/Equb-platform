import 'package:flutter/material.dart';
import '../../data/notifications_repository.dart';
import './notification_detail_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationsRepository _repository = NotificationsRepository();

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _unreadCount = 0;

  static const Color primaryOrange = Color(0xFFFF5C00);
  static const Color headerTextDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color pageBg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _repository.getNotifications();
      final List rawList = res['data'] is List
          ? res['data']
          : (res['notifications'] is List ? res['notifications'] : []);

      final parsed = rawList
          .map((item) => item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{})
          .toList();

      if (mounted) {
        setState(() {
          _notifications = parsed;
          _unreadCount = res['unread_count'] is int
              ? res['unread_count']
              : _notifications.where((n) => n['is_read'] != true).length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll("Exception: ", "");
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(Map<String, dynamic> item) async {
    final id = item['notification_id']?.toString() ?? item['id']?.toString();
    if (id == null || item['is_read'] == true) return;

    setState(() {
      item['is_read'] = true;
      if (_unreadCount > 0) _unreadCount--;
    });

    try {
      await _repository.markAsRead(id);
    } catch (_) {
      // Silently fail or ignore in background
    }
  }

  Future<void> _markAllAsRead() async {
    if (_notifications.isEmpty) return;

    setState(() {
      for (var item in _notifications) {
        item['is_read'] = true;
      }
      _unreadCount = 0;
    });

    try {
      await _repository.markAllAsRead();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All notifications marked as read"),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      _loadNotifications();
    }
  }

  Future<void> _deleteNotification(Map<String, dynamic> item, int index) async {
    final id = item['notification_id']?.toString() ?? item['id']?.toString();
    if (id == null) return;

    final removedItem = _notifications.removeAt(index);
    setState(() {});

    try {
      await _repository.deleteNotification(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Notification deleted"),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: "Undo",
            textColor: primaryOrange,
            onPressed: () {
              setState(() {
                _notifications.insert(index, removedItem);
              });
            },
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _notifications.insert(index, removedItem);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to delete notification"),
            backgroundColor: Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openNotificationDetail(Map<String, dynamic> item) {
    _markAsRead(item);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationDetailPage(notification: item),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Just now";
    try {
      final date = timestamp is DateTime ? timestamp : DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return "Just now";
      if (diff.inMinutes < 60) return "${diff.inMinutes} mins ago";
      if (diff.inHours < 24) return "${diff.inHours} hr${diff.inHours > 1 ? 's' : ''} ago";
      if (diff.inDays == 1) return "Yesterday";
      if (diff.inDays < 7) return "${diff.inDays} days ago";
      return "${date.day}/${date.month}/${date.year}";
    } catch (_) {
      return timestamp.toString();
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'payment_reminder':
      case 'overdue_alert':
      case 'payment':
        return Icons.account_balance_wallet_outlined;
      case 'group_activity':
      case 'group_completed':
      case 'group_update':
      case 'member_joined':
        return Icons.groups_rounded;
      case 'security_alert':
      case 'alert':
      case 'security':
        return Icons.shield_outlined;
      case 'payout_received':
      case 'payment_success':
      case 'payout':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  _TypeColors _getColorsForType(String type) {
    switch (type) {
      case 'payment_reminder':
      case 'overdue_alert':
      case 'payment':
        return const _TypeColors(
          bgColor: Color(0xFFFFEDD5),
          iconColor: Color(0xFFEA580C),
        );
      case 'group_activity':
      case 'group_completed':
      case 'group_update':
      case 'member_joined':
        return const _TypeColors(
          bgColor: Color(0xFFDCFCE7),
          iconColor: Color(0xFF16A34A),
        );
      case 'security_alert':
      case 'alert':
      case 'security':
        return const _TypeColors(
          bgColor: Color(0xFFE0F2FE),
          iconColor: Color(0xFF0284C7),
        );
      case 'payout_received':
      case 'payment_success':
      case 'payout':
        return const _TypeColors(
          bgColor: Color(0xFFFFEDD5),
          iconColor: Color(0xFFEA580C),
        );
      default:
        return const _TypeColors(
          bgColor: Color(0xFFF1F5F9),
          iconColor: Color(0xFF64748B),
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
          "Notifications",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: headerTextDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: Color(0xFF475569),
              size: 24,
            ),
            tooltip: "Notification Settings",
            onPressed: () {
              Navigator.pushNamed(context, '/notifications/settings');
            },
          ),
          if (_notifications.any((n) => n['is_read'] != true))
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF475569)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (val) {
                if (val == 'mark_all_read') {
                  _markAllAsRead();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.done_all_rounded, color: primaryOrange, size: 20),
                      SizedBox(width: 10),
                      Text(
                        "Mark all as read",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: primaryOrange,
          strokeWidth: 2.5,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFDC2626),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14.5,
                  color: headerTextDark,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadNotifications,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text("Retry"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadNotifications,
        color: primaryOrange,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.22),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryOrange.withValues(alpha: 0.25),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: primaryOrange,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "No Notifications",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: headerTextDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "You're all caught up! Updates will appear here.",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13.5,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: primaryOrange,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _notifications[index];
          return _buildNotificationCard(item, index);
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item, int index) {
    final isRead = item['is_read'] == true;
    final title = (item['title'] ?? 'Notification').toString();
    final message = (item['message'] ?? '').toString();
    final type = (item['type'] ?? 'update').toString().toLowerCase();
    final timeStr = _formatTimestamp(item['created_at']);
    final iconData = _getIconForType(type);
    final colors = _getColorsForType(type);

    return Dismissible(
      key: Key(item['notification_id']?.toString() ?? 'notif_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => _deleteNotification(item, index),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openNotificationDetail(item),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Unread indicator vertical orange strip on left edge
                if (!isRead)
                  Positioned(
                    left: 0,
                    top: 14,
                    bottom: 14,
                    child: Container(
                      width: 4.5,
                      decoration: const BoxDecoration(
                        color: primaryOrange,
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Circular Type Icon Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colors.bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            iconData,
                            color: colors.iconColor,
                            size: 24,
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Content Body
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title and Timestamp row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: headerTextDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  timeStr,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: textMuted,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            // Message Preview
                            Text(
                              message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w400,
                                color: textMuted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _TypeColors {
  final Color bgColor;
  final Color iconColor;
  const _TypeColors({required this.bgColor, required this.iconColor});
}
