import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/profile_service.dart';
import '../../../../core/utils/test_otp_dialog.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  static const Color primaryOrange = Color(0xFFF97316);
  static const Color headerOrange = Color(0xFFEA580C);
  static const Color textDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE2E8F0);

  // Step state: 0 = Input Passwords, 1 = Verify OTP
  int _currentStep = 0;

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // OTP controllers & focus nodes
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  String? _maskedPhone;
  String? _currentOtp;

  // Timer for OTP resend
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  @override
  void dispose() {
    _timer?.cancel();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Step 1: Validate passwords and request OTP
  Future<void> _handleRequestOTP() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty) {
      _showError("Please enter your current (old) password");
      return;
    }

    if (newPassword.isEmpty) {
      _showError("Please enter a new password");
      return;
    }

    if (newPassword.length < 6) {
      _showError("New password must be at least 6 characters long");
      return;
    }

    if (confirmPassword.isEmpty) {
      _showError("Please confirm your new password");
      return;
    }

    if (newPassword != confirmPassword) {
      _showError("New password and confirm password do not match");
      return;
    }

    if (currentPassword == newPassword) {
      _showError("New password must be different from your current password");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ProfileService.requestPasswordChangeOTP(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (!mounted) return;

      setState(() {
        _maskedPhone = res['masked_phone'] ?? res['phone'];
        _currentStep = 1;
        _isLoading = false;
      });

      _startResendTimer();
      _showSuccess("Verification code sent to your registered phone number!");

      // If test OTP is returned, display test alert popup and banner
      final otpVal = (res['otp'] ?? res['otp_code'] ?? res['data']?['otp'])?.toString();
      if (otpVal != null && otpVal.isNotEmpty) {
        setState(() {
          _currentOtp = otpVal;
        });
        showTestOtpPopup(context, otp: otpVal, title: "Password Change OTP");
      }

      // Focus first OTP box
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _otpFocusNodes[0].requestFocus();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // Resend OTP
  Future<void> _handleResendOTP() async {
    if (!_canResend) return;

    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;

    setState(() => _isLoading = true);

    try {
      final res = await ProfileService.requestPasswordChangeOTP(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (!mounted) return;

      setState(() {
        _maskedPhone = res['masked_phone'] ?? res['phone'];
        _isLoading = false;
      });

      _startResendTimer();
      _showSuccess("A new verification code has been sent!");

      final otpVal = (res['otp'] ?? res['otp_code'] ?? res['data']?['otp'])?.toString();
      if (otpVal != null && otpVal.isNotEmpty) {
        setState(() {
          _currentOtp = otpVal;
        });
        showTestOtpPopup(context, otp: otpVal, title: "Password Change OTP");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // Step 2: Confirm OTP and finalize password change
  Future<void> _handleConfirmChangePassword() async {
    final otp = _otpControllers.map((c) => c.text.trim()).join();
    if (otp.length != 6) {
      _showError("Please enter the complete 6-digit verification code");
      return;
    }

    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;

    setState(() => _isLoading = true);

    try {
      final res = await ProfileService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        otpCode: otp,
      );

      if (!mounted) return;

      _showSuccess(res['message'] ?? "Password changed successfully!");
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e.toString().replaceAll("Exception: ", ""));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _currentStep == 0 ? "Change Password" : "Verify Code",
          style: const TextStyle(
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
            if (_currentStep == 1) {
              setState(() => _currentStep = 0);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: _currentStep == 0
              ? _buildPasswordInputStep()
              : _buildOtpVerificationStep(),
        ),
      ),
    );
  }

  /// Step 1: Input Old Password, New Password, Confirm New Password
  Widget _buildPasswordInputStep() {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;
    final currentPass = _currentPasswordController.text;
    final hasMinLength = newPass.length >= 6;
    final passwordsMatch = newPass.isNotEmpty && confirmPass.isNotEmpty && newPass == confirmPass;
    final isDifferentFromOld = currentPass.isNotEmpty && newPass.isNotEmpty && currentPass != newPass;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Security Header Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryOrange.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryOrange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined, color: headerOrange, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Secure Password Update",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: textDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Enter your old password, choose a new password, and verify via OTP.",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: textMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 26),

        // Old / Current Password
        const Text(
          "Old Password (Current)",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: textDark,
          ),
        ),
        const SizedBox(height: 8),
        _buildPasswordField(
          controller: _currentPasswordController,
          hintText: "Enter your current password",
          obscureText: _obscureCurrent,
          onChanged: (_) => setState(() {}),
          onToggleVisibility: () => setState(() => _obscureCurrent = !_obscureCurrent),
        ),

        const SizedBox(height: 20),

        // New Password
        const Text(
          "New Password",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: textDark,
          ),
        ),
        const SizedBox(height: 8),
        _buildPasswordField(
          controller: _newPasswordController,
          hintText: "Enter new password (min. 6 characters)",
          obscureText: _obscureNew,
          onChanged: (_) => setState(() {}),
          onToggleVisibility: () => setState(() => _obscureNew = !_obscureNew),
        ),

        const SizedBox(height: 20),

        // Confirm New Password
        const Text(
          "Confirm New Password",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: textDark,
          ),
        ),
        const SizedBox(height: 8),
        _buildPasswordField(
          controller: _confirmPasswordController,
          hintText: "Re-enter new password",
          obscureText: _obscureConfirm,
          onChanged: (_) => setState(() {}),
          onToggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),

        const SizedBox(height: 20),

        // Password Checklist
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              _buildRequirementRow(
                isValid: hasMinLength,
                text: "At least 6 characters long",
              ),
              const SizedBox(height: 8),
              _buildRequirementRow(
                isValid: passwordsMatch,
                text: "New password and confirmation match",
              ),
              if (currentPass.isNotEmpty && newPass.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildRequirementRow(
                  isValid: isDifferentFromOld,
                  text: "Different from current password",
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Continue / Send OTP Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleRequestOTP,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  /// Step 2: 6-Digit OTP Verification
  Widget _buildOtpVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 10),

        // OTP Top Icon
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            shape: BoxShape.circle,
            border: Border.all(color: primaryOrange.withValues(alpha: 0.3), width: 2),
          ),
          child: const Center(
            child: Icon(
              Icons.mark_email_read_rounded,
              color: headerOrange,
              size: 32,
            ),
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          "Enter Verification Code",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),

        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "We've sent a 6-digit code to ${_maskedPhone ?? 'your phone number'} to authorize this password change.",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13.5,
              color: textMuted,
              height: 1.4,
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Visible OTP Card (100% visible on-screen for testing/deployment)
        if (_currentOtp != null && _currentOtp!.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryOrange, width: 1.5),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mark_email_read_rounded, color: headerOrange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "VERIFICATION CODE",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 1,
                        color: Color(0xFF9A3412),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  _currentOtp!,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w900,
                    fontSize: 32,
                    letterSpacing: 6,
                    color: headerOrange,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _currentOtp!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Code copied to clipboard!"),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.copy_rounded, color: headerOrange, size: 16),
                        SizedBox(width: 6),
                        Text(
                          "Copy Code",
                          style: TextStyle(
                            color: headerOrange,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        // 6 OTP Digit Boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) => _buildOtpBox(index)),
        ),

        const SizedBox(height: 28),

        // Resend Timer Row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _canResend
                  ? "Didn't receive the code? "
                  : "Resend code in ",
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13.5,
                color: textMuted,
              ),
            ),
            if (!_canResend)
              Text(
                "0:${_secondsRemaining.toString().padLeft(2, '0')}",
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: headerOrange,
                ),
              )
            else
              GestureDetector(
                onTap: _isLoading ? null : _handleResendOTP,
                child: const Text(
                  "Resend Code",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: headerOrange,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 36),

        // Confirm Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleConfirmChangePassword,
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
                    "Confirm & Update Password",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // Back to Edit Link
        TextButton(
          onPressed: () => setState(() => _currentStep = 0),
          child: const Text(
            "Change password details",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textDark,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: borderColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primaryOrange, width: 2),
          ),
        ),
        onChanged: (val) {
          if (val.isNotEmpty) {
            if (index < 5) {
              _otpFocusNodes[index + 1].requestFocus();
            } else {
              _otpFocusNodes[index].unfocus();
              // Automatically submit when all 6 digits entered
              _handleConfirmChangePassword();
            }
          } else if (val.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
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
        controller: controller,
        obscureText: obscureText,
        onChanged: onChanged,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(Icons.lock_outline_rounded, color: primaryOrange, size: 22),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: const Color(0xFF94A3B8),
              size: 20,
            ),
            onPressed: onToggleVisibility,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildRequirementRow({
    required bool isValid,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 16,
          color: isValid ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12.5,
            fontWeight: isValid ? FontWeight.w600 : FontWeight.w400,
            color: isValid ? const Color(0xFF16A34A) : textMuted,
          ),
        ),
      ],
    );
  }
}
