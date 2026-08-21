import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/error_snackbar.dart';
import '../../data/sessions_service.dart';

class ActiveSessionsPage extends StatefulWidget {
  const ActiveSessionsPage({super.key});

  @override
  State<ActiveSessionsPage> createState() => _ActiveSessionsPageState();
}

class _ActiveSessionsPageState extends State<ActiveSessionsPage> {
  final _service = SessionsService();
  List<dynamic> _sessions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.getSessions();
      if (mounted) setState(() { _sessions = data; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() { _loading = false; _error = 'Failed to load sessions'; });
      }
    }
  }

  Future<void> _revoke(String tokenId) async {
    try {
      await _service.revokeSession(tokenId);
      _load();
    } catch (e) {
      if (mounted) ErrorSnackbar.show(context, 'Failed to revoke session');
    }
  }

  Future<void> _revokeAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke All Other Sessions', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: const Text('This will sign out all other devices. Continue?', style: TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Revoke All', style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _service.revokeAllOthers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All other sessions revoked'), backgroundColor: AppTheme.success),
        );
        _load();
      }
    } catch (e) {
      if (mounted) ErrorSnackbar.show(context, 'Failed to revoke sessions');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Active Sessions', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
        actions: [
          if (_sessions.length > 1)
            TextButton(
              onPressed: _revokeAll,
              child: const Text('Revoke All', style: TextStyle(fontFamily: 'Poppins', color: AppTheme.error, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _loading,
        child: _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.error),
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              )
            : _sessions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.devices_rounded, size: 64, color: AppTheme.grayText),
                        SizedBox(height: 16),
                        Text('No active sessions found', style: TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 15)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppTheme.primary,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _sessions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final s = _sessions[i] as Map<String, dynamic>;
                        final isCurrent = s['is_current'] == true;
                        final device = s['device_type'] ?? 'Unknown Device';
                        final lastUsed = _formatDate(s['last_used']);
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: isCurrent ? Border.all(color: AppTheme.primary, width: 1.5) : null,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                                child: Icon(
                                  device.toLowerCase().contains('android') ? Icons.smartphone_rounded
                                      : device.toLowerCase().contains('ios') ? Icons.phone_iphone_rounded
                                      : Icons.computer_rounded,
                                  color: AppTheme.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(device, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.darkText)),
                                    Text('Last active: $lastUsed', style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 12)),
                                  ],
                                ),
                              ),
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                  child: const Text('This Device', style: TextStyle(fontFamily: 'Poppins', color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                                )
                              else
                                IconButton(
                                  icon: const Icon(Icons.exit_to_app_rounded, color: AppTheme.error, size: 20),
                                  tooltip: 'Revoke session',
                                  onPressed: () => _revoke(s['token_id'] ?? ''),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    try {
      final d = DateTime.parse(date.toString()).toLocal();
      final now = DateTime.now();
      final diff = now.difference(d);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return date.toString();
    }
  }
}
