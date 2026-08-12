import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ActiveSessionsPage extends StatefulWidget {
  const ActiveSessionsPage({super.key});

  @override
  State<ActiveSessionsPage> createState() => _ActiveSessionsPageState();
}

class _ActiveSessionsPageState extends State<ActiveSessionsPage> {
  final List<Map<String, dynamic>> _sessions = [
    {'device': 'Android 13 - Samsung S22', 'location': 'Addis Ababa, ET', 'current': true, 'lastActive': 'Active Now'},
    {'device': 'Chrome Browser - Windows', 'location': 'Addis Ababa, ET', 'current': false, 'lastActive': '2 hours ago'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Active Sessions', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _sessions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final s = _sessions[i];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: s['current'] == true ? Border.all(color: AppTheme.primary, width: 1.5) : null,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Icon(
                  s['device'].toString().contains('Android') ? Icons.smartphone_rounded : Icons.computer_rounded,
                  color: AppTheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['device'], style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.darkText)),
                      Text('${s['location']} • ${s['lastActive']}', style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 12)),
                    ],
                  ),
                ),
                if (s['current'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Text('Current', style: TextStyle(fontFamily: 'Poppins', color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.exit_to_app_rounded, color: AppTheme.error, size: 20),
                    onPressed: () => setState(() => _sessions.removeAt(i)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
