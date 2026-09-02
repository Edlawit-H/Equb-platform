import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AboutEqubPage extends StatelessWidget {
  const AboutEqubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'About Equb',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.savings_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Equb',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Traditional savings, made digital.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // What is Equb
            _InfoCard(
              icon: Icons.info_outline_rounded,
              title: 'What is Equb?',
              body:
                  'Equb is a centuries-old Ethiopian community savings tradition. '
                  'Members of a trusted group each contribute an equal amount every cycle, '
                  'and one member receives the full pooled amount. This continues until '
                  'every member has received their payout.',
            ),

            const SizedBox(height: 12),

            // How it works
            _InfoCard(
              icon: Icons.autorenew_rounded,
              title: 'How It Works',
              body:
                  '1. An admin creates an Equb group and sets the contribution amount and cycle length.\n'
                  '2. Members join before the group starts.\n'
                  '3. Once the group starts, each member contributes every cycle.\n'
                  '4. The system assigns the pooled amount to one member per cycle.\n'
                  '5. This repeats until every member has received their payout.',
            ),

            const SizedBox(height: 12),

            // Why digital
            _InfoCard(
              icon: Icons.smartphone_rounded,
              title: 'Why Digital?',
              body:
                  'Bringing Equb online means transparent contribution tracking, '
                  'automatic payout processing, real-time notifications, and a '
                  'reliable record of every transaction removing the manual '
                  'coordination and trust risks of paper-based systems.',
            ),

            const SizedBox(height: 12),

            // Version card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.tag_rounded, color: AppTheme.grayText, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppTheme.grayText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _InfoCard({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppTheme.grayText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
