import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  final faqs = const [
    {'q': 'What is Equb?', 'a': 'Equb is a traditional Ethiopian community savings system where members contribute equally every cycle and take turns receiving the pooled amount, now brought online for transparency and ease.'},
    {'q': 'How are payouts determined?', 'a': 'Payouts are determined automatically by our fair algorithm or by admin approval at the end of each contribution cycle.'},
    {'q': 'Is my wallet balance safe?', 'a': 'Yes, all wallet operations are secured with state-of-the-art encryption and full transaction logging.'},
    {'q': 'How do I join an Equb group?', 'a': 'Navigate to the Groups tab on the main navigation bar and tap Join Group or enter an invitation code.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Help & Support', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.support_agent_rounded, color: AppTheme.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Need Assistance?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.darkText)),
                        Text('Our team is here 24/7 to help you.', style: TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Frequently Asked Questions', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkText)),
            const SizedBox(height: 12),
            ...faqs.map((faq) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: ExpansionTile(
                title: Text(faq['q']!, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.darkText)),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    child: Text(faq['a']!, style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.grayText, fontSize: 13, height: 1.4)),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}


