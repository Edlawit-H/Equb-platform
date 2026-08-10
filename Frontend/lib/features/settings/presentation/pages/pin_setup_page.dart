import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_snackbar.dart';

class PinSetupPage extends StatefulWidget {
  const PinSetupPage({super.key});

  @override
  State<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<PinSetupPage> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;

  void _onKeyPress(String val) {
    if (_isConfirming) {
      if (_confirmPin.length < 4) {
        setState(() => _confirmPin += val);
        if (_confirmPin.length == 4) _verifyAndSave();
      }
    } else {
      if (_pin.length < 4) {
        setState(() => _pin += val);
        if (_pin.length == 4) {
          Future.delayed(const Duration(milliseconds: 200), () {
            setState(() => _isConfirming = true);
          });
        }
      }
    }
  }

  void _onDelete() {
    setState(() {
      if (_isConfirming) {
        if (_confirmPin.isNotEmpty) _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      } else {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  void _verifyAndSave() {
    if (_pin == _confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN successfully set!'), backgroundColor: AppTheme.success),
      );
      Navigator.pop(context);
    } else {
      ErrorSnackbar.show(context, 'PINs do not match. Try again.');
      setState(() {
        _pin = '';
        _confirmPin = '';
        _isConfirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentText = _isConfirming ? _confirmPin : _pin;
    final title = _isConfirming ? 'Confirm PIN' : 'Create 4-Digit PIN';
    final subtitle = _isConfirming ? 'Re-enter your PIN to verify' : 'Secure your account with a PIN';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('PIN Setup', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppTheme.grayText)),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final isFilled = i < currentText.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 20,
                height: 20,
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
