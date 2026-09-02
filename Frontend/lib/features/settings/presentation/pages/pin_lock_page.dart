import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class PinLockPage extends StatefulWidget {
  const PinLockPage({super.key});

  @override
  State<PinLockPage> createState() => _PinLockPageState();
}

class _PinLockPageState extends State<PinLockPage> {
  String _pin = '';

  void _onKeyPress(String val) {
    if (_pin.length < 4) {
      setState(() => _pin += val);
      if (_pin.length == 4) {
        // Unlock simulation
        Future.delayed(const Duration(milliseconds: 200), () {
          Navigator.pop(context, true);
        });
      }
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.lock_rounded, color: AppTheme.primary, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('Enter Your PIN', style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
            const SizedBox(height: 8),
            const Text('Verify your identity to proceed', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppTheme.grayText)),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final isFilled = i < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppTheme.primary : const Color(0xFFE5E7EB),
                  ),
                );
              }),
            ),
            const Spacer(),
            _Keypad(onKey: _onKeyPress, onDelete: _onDelete),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final ValueChanged<String> onKey;
  final VoidCallback onDelete;
  const _Keypad({required this.onKey, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del']
    ];

    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: row.map((key) {
            if (key.isEmpty) return const SizedBox(width: 70, height: 70);
            if (key == 'del') {
              return IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.backspace_outlined, size: 24, color: AppTheme.darkText),
                constraints: const BoxConstraints.tightFor(width: 70, height: 70),
              );
            }
            return InkWell(
              onTap: () => onKey(key),
              borderRadius: BorderRadius.circular(35),
              child: SizedBox(
                width: 70,
                height: 70,
                child: Center(
                  child: Text(
                    key,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.darkText),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

