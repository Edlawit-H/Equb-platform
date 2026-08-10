import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  String _selected = 'en';

  final languages = [
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'am', 'name': 'Amharic', 'native': 'አማርኛ'},
    {'code': 'om', 'name': 'Oromo', 'native': 'Afaan Oromoo'},
    {'code': 'ti', 'name': 'Tigrinya', 'native': 'ትግርኛ'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Language', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: languages.asMap().entries.map((e) {
                  final lang = e.value;
                  final isSelected = _selected == lang['code'];
                  final isLast = e.key == languages.length - 1;

                  return Column(
                    children: [
                      ListTile(
                        title: Text(lang['name']!, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(lang['native']!, style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 12)),
                        trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary) : null,
                        onTap: () => setState(() => _selected = lang['code']!),
                      ),
                      if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
                    ],
                  );
                }).toList(),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Save Preference', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
