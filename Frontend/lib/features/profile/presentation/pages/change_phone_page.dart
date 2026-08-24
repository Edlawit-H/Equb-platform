import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/profile_service.dart';

class ChangePhonePage extends StatefulWidget {
  final String currentPhone;

  const ChangePhonePage({
    super.key,
    this.currentPhone = '',
  });

  @override
  State<ChangePhonePage> createState() => _ChangePhonePageState();
}

class _ChangePhonePageState extends State<ChangePhonePage> {
  static const Color primaryOrange = Color(0xFFF97316);
  static const Color headerOrange = Color(0xFFEA580C);
  static const Color textDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const int otpLength = 6;

  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(otpLength, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(otpLength, (_) => FocusNode());

  int _step = 1; // 1 = Enter Phone, 2 = Verify OTP
  bool _isLoading = false;
  bool _isResending = false;

  Timer? _timer;
  int _resendCountdown = 60;
  bool _canResend = false;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendCountdown = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        if (mounted) setState(() => _resendCountdown--);
      } else {
        if (mounted) setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  void _onDigitChanged(String value, int index) {
    if (value.length > 1) {
      final clean = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < otpLength; i++) {
        if (i < clean.length) {
          _otpControllers[i].text = clean[i];
        }
      }
      if (clean.length >= otpLength) {
        _otpFocusNodes[otpLength - 1].requestFocus();
      } else {
        _otpFocusNodes[clean.length].requestFocus();
      }
      setState(() {});
      return;
    }

    if (value.isNotEmpty) {
      if (index < otpLength - 1) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        _otpFocusNodes[index].unfocus();
      }
    }
    setState(() {});
  }

  void _onKeyDown(KeyEvent event, int index) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_otpControllers[index].text.isEmpty && index > 0) {
        _otpControllers[index - 1].clear();
        _otpFocusNodes[index - 1].requestFocus();
        setState(() {});
      }
    }
  }

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showError("Please enter your new phone number");
      return;
    }

    if (phone.length < 9) {
      _showError("Please enter a valid phone number (e.g. 0912345678 or +251912345678)");
      return;
    }

    if (widget.currentPhone.isNotEmpty &&
        (widget.currentPhone.trim() == phone ||
            widget.currentPhone.replaceAll('+251', '0') == phone.replaceAll('+251', '0'))) {
      _showError("The new phone number must be different from your current number");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ProfileService.requestPhoneChangeOTP(newPhone: phone);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? "OTP sent to $phone"),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );

      setState(() {
        _step = 2;
        _isLoading = false;
      });
      _startResendTimer();
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll("Exception: ", ""));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResendOtp() async {
    if (!_canResend || _isResending) return;

    setState(() => _isResending = true);
    final phone = _phoneController.text.trim();

    try {
      final res = await ProfileService.requestPhoneChangeOTP(newPhone: phone);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? "OTP resent successfully!"),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );

      _startResendTimer();
      for (var c in _otpControllers) {
        c.clear();
      }
      if (_otpFocusNodes.isNotEmpty) {
        _otpFocusNodes[0].requestFocus();
      }
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpCode.trim();
    if (otp.length < otpLength) {
      _showError("Please enter the complete 6-digit OTP code");
      return;
    }

    final phone = _phoneController.text.trim();
    setState(() => _isLoading = true);

    try {
      await ProfileService.verifyPhoneChangeOTP(newPhone: phone, otp: otp);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Phone number updated successfully!"),
          backgroundColor: Color(0xFF16A34A),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Change Phone Number",
          style: TextStyle(
            color: textDark,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 20),
          onPressed: () {
            if (_step == 2) {
              setState(() => _step = 1);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: _step == 1 ? _buildStep1PhoneInput() : _buildStep2OtpInput(),
        ),
      ),
    );
  }

  Widget _buildStep1PhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Security Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryOrange.withValues(alpha: 0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryOrange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined, color: headerOrange, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Secure Phone Verification",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: textDark,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "We will send a 6-digit OTP to verify your new phone number before updating your account.",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
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

        const SizedBox(height: 24),

        // Current Phone Display
        if (widget.currentPhone.isNotEmpty) ...[
          const Text(
            "Current Phone Number",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.phone_outlined, color: textMuted, size: 18),
                const SizedBox(width: 10),
                Text(
                  widget.currentPhone,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // New Phone Input
        const Text(
          "New Phone Number",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCBD5E1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
            decoration: const InputDecoration(
              hintText: "e.g. 0912345678 or +251912345678",
              hintStyle: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Color(0xFF94A3B8),
              ),
              prefixIcon: Icon(Icons.phone_android_rounded, color: primaryOrange, size: 22),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Send OTP Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Send Verification Code",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2OtpInput() {
    final phone = _phoneController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Enter Verification Code",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                "A 6-digit code was sent to $phone",
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.5,
                  color: textMuted,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _step = 1),
              child: const Text(
                "Edit",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: primaryOrange,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // 6 OTP Box Inputs
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(otpLength, (index) => _buildOtpBox(index)),
        ),

        const SizedBox(height: 36),

        // Verify Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleVerifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text(
                    "Verify & Update Phone",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 24),

        // Resend Section
        Center(
          child: _isResending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: primaryOrange, strokeWidth: 2),
                )
              : _canResend
                  ? GestureDetector(
                      onTap: _handleResendOtp,
                      child: const Text(
                        "Didn't receive code? Resend OTP",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: primaryOrange,
                        ),
                      ),
                    )
                  : Text(
                      "Resend code in ${_resendCountdown}s",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.5,
                        color: textMuted,
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildOtpBox(int index) {
    final isFocused = _otpFocusNodes[index].hasFocus;
    final hasValue = _otpControllers[index].text.isNotEmpty;

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) => _onKeyDown(event, index),
      child: Container(
        width: 46,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isFocused
                ? primaryOrange
                : (hasValue ? primaryOrange.withValues(alpha: 0.6) : const Color(0xFFE2E8F0)),
            width: isFocused ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _otpFocusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textDark,
              fontFamily: 'Poppins',
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) => _onDigitChanged(value, index),
          ),
        ),
      ),
    );
  }
}
