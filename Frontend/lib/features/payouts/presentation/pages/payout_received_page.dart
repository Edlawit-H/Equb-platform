import 'package:flutter/material.dart';

class PayoutReceivedPage extends StatelessWidget {
  final double? amount;
  final String? groupName;
  final int? cycleNumber;
  final String? recipientName;

  const PayoutReceivedPage({
    super.key,
    this.amount,
    this.groupName,
    this.cycleNumber,
    this.recipientName,
  });

  static const Color primaryOrange = Color(0xFFF97316);
  static const Color activeGreen = Color(0xFF16A34A);
  static const Color textDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final displayAmount = amount ?? 15000.00;
    final group = groupName ?? 'Equb Circle';
    final cycle = cycleNumber ?? 1;
    final recipient = recipientName ?? 'You';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Payout Notification',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFEA580C),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Celebration Trophy Circle with Badges
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFF7ED),
                      border: Border.all(color: primaryOrange.withValues(alpha: 0.3), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: primaryOrange.withValues(alpha: 0.2),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 110,
                    height: 110,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.emoji_events_rounded, color: Colors.white, size: 56),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Congratulations Header
              const Text(
                '🎉 Congratulations! 🎉',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  color: textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '$recipient was selected for the Cycle #$cycle payout!',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: textMuted,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Amount Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'TOTAL PAYOUT RECEIVED',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: textMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ETB ${displayAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w900,
                        fontSize: 32,
                        color: activeGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: activeGreen, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Credited to Digital Wallet',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: activeGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Equb Circle',
                          style: TextStyle(fontFamily: 'Poppins', color: textMuted, fontSize: 13),
                        ),
                        Text(
                          group,
                          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: textDark, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Cycle Round',
                          style: TextStyle(fontFamily: 'Poppins', color: textMuted, fontSize: 13),
                        ),
                        Text(
                          'Round #$cycle',
                          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: textDark, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/wallet'),
                  icon: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
                  label: const Text(
                    'View My Wallet Balance',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/payouts/schedule'),
                  icon: const Icon(Icons.timeline_rounded, color: textDark),
                  label: const Text(
                    'View Rotation Timeline',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: textDark),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
