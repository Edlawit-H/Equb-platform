import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/otp_verification_page.dart';
import 'features/auth/presentation/pages/forgot_password_page.dart';
import 'features/auth/presentation/pages/reset_password_page.dart';
import 'features/dashboard/presentation/home_screen.dart';
void main() {
  runApp(const ProviderScope(child: EqubApp()));
}

class EqubApp extends StatelessWidget {
  const EqubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Equb',
      theme: AppTheme.light,
      initialRoute: '/login',
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/otp': (context) => const OtpScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/home': (context) => const HomeScreen(),
      },
      onGenerateRoute: onGenerateAppRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
