import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/biometric_setup_page.dart';
import '../../features/groups/presentation/pages/my_groups_page.dart';
import '../../features/groups/presentation/pages/create_group_page.dart';
import '../../features/groups/presentation/pages/join_group_page.dart';
import '../../features/groups/presentation/pages/group_detail_page.dart';
import '../../features/groups/presentation/pages/group_members_page.dart';
import '../../features/groups/presentation/pages/group_dashboard_page.dart';
import '../../features/groups/presentation/pages/group_settings_page.dart';
import '../../features/groups/presentation/pages/group_activity_page.dart';
import '../../features/groups/presentation/pages/invite_members_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/change_password_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/notifications/presentation/pages/notification_detail_page.dart';
import '../../features/notifications/presentation/pages/notification_settings_page.dart';
import '../../features/dashboard/presentation/home_screen.dart';
import '../../features/reports/presentation/pages/analytics_dashboard_page.dart';
import '../../features/reports/presentation/pages/export_report_page.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';
import '../../features/wallet/presentation/pages/top_up_page.dart';
import '../../features/wallet/presentation/pages/transaction_list_page.dart';
import '../../features/wallet/presentation/pages/transaction_detail_page.dart';
import '../../features/contributions/presentation/pages/contribution_list_page.dart';
import '../../features/contributions/presentation/pages/contribution_detail_page.dart';
import '../../features/contributions/presentation/pages/pay_contribution_page.dart';
import '../../features/payouts/presentation/pages/payout_schedule_page.dart';
import '../../features/payouts/presentation/pages/payout_history_page.dart';
import '../../features/payouts/presentation/pages/payout_detail_page.dart';
import '../../features/payouts/presentation/pages/payout_received_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/language_page.dart';
import '../../features/settings/presentation/pages/pin_setup_page.dart';
import '../../features/settings/presentation/pages/pin_lock_page.dart';
import '../../features/settings/presentation/pages/active_sessions_page.dart';
import '../../features/settings/presentation/pages/help_support_page.dart';

Route<dynamic> onGenerateAppRoute(RouteSettings settings) {
  final name = settings.name ?? '/';
  final args = settings.arguments;

  Widget page;

  // Entry & Auth Routes
  if (name == '/' || name == '/splash') {
    page = const SplashPage();
  } else if (name == '/onboarding') {
    page = const OnboardingPage();
  } else if (name == '/login') {
    page = const LoginScreen();
  } else if (name == '/register') {
    page = const RegisterScreen();
  } else if (name == '/otp') {
    page = const OtpScreen();
  } else if (name == '/forgot-password') {
    page = const ForgotPasswordScreen();
  } else if (name == '/reset-password') {
    page = const ResetPasswordScreen();
  } else if (name == '/biometric-setup') {
    page = const BiometricSetupPage();
  }
  // Group Management Routes
  else if (name == '/groups') {
    page = const GroupsPage();
  } else if (name == '/groups/create') {
    page = const CreateGroupScreen();
  } else if (name == '/groups/join') {
    page = const JoinGroupPage();
  } else if (name == '/groups/detail') {
    page = const GroupDetailsPage();
  } else if (name == '/groups/members') {
    page = const GroupMembersPage();
  } else if (name == '/groups/dashboard') {
    page = const GroupDashboardPage();
  } else if (name == '/groups/settings') {
    page = const GroupSettingsPage();
  } else if (name == '/groups/activity') {
    page = const GroupActivityPage();
  } else if (name == '/groups/invite') {
    page = const InviteMembersPage();
  }
  // User Profile Routes
  else if (name == '/profile') {
    page = const ProfilePage();
  } else if (name == '/profile/edit') {
    page = const EditProfilePage();
  } else if (name == '/change-password') {
    page = const ChangePasswordPage();
  }
  // Notification Routes
  else if (name == '/notifications') {
    page = const NotificationsPage();
  } else if (name == '/notifications/detail') {
    page = const NotificationDetailPage();
  } else if (name == '/notifications/settings') {
    page = const NotificationSettingsPage();
  }
  // Core Routes
  else if (name == '/home' || name == '/dashboard') {
    page = const HomeScreen();
  } else if (name == '/wallet') {
    page = const WalletPage();
  } else if (name == '/wallet/top-up') {
    page = const TopUpPage();
  } else if (name == '/transactions') {
    page = const TransactionListPage();
  } else if (name.startsWith('/transactions/')) {
    final id = name.replaceFirst('/transactions/', '');
    page = TransactionDetailPage(transactionId: id);
  } else if (name == '/contributions') {
    page = const ContributionListPage();
  } else if (name.startsWith('/contributions/pay')) {
    page = PayContributionPage(
        contribution: (args as Map<String, dynamic>?) ?? {});
  } else if (name.startsWith('/contributions/')) {
    final id = name.replaceFirst('/contributions/', '');
    page = ContributionDetailPage(contributionId: id);
  } else if (name == '/payouts/schedule') {
    final gId = (args is Map) ? args['group_id']?.toString() : (args is String ? args : null);
    final gName = (args is Map) ? args['group_name']?.toString() : null;
    page = PayoutSchedulePage(groupId: gId, groupName: gName);
  } else if (name == '/payouts/history') {
    final gId = (args is Map) ? args['group_id']?.toString() : (args is String ? args : null);
    page = PayoutHistoryPage(groupId: gId);
  } else if (name == '/payouts/notification' || name == '/payouts/received' || name == '/payouts/won') {
    final map = args is Map<String, dynamic> ? args : <String, dynamic>{};
    page = PayoutReceivedPage(
      amount: map['amount'] is num ? (map['amount'] as num).toDouble() : null,
      groupName: map['group_name']?.toString(),
      cycleNumber: map['cycle_number'] is int ? map['cycle_number'] as int : null,
      recipientName: map['recipient_name']?.toString(),
    );
  } else if (name.startsWith('/payouts/')) {
    final id = name.replaceFirst('/payouts/', '');
    page = PayoutDetailPage(payoutId: id);
  } else if (name == '/reports') {
    page = const AnalyticsDashboardPage();
  } else if (name == '/reports/export') {
    page = ExportReportPage(
        groupId: (args as Map<String, dynamic>?)?['group_id']?.toString());
  } else if (name == '/settings') {
    page = const SettingsPage();
  } else if (name == '/settings/language') {
    page = const LanguagePage();
  } else if (name == '/settings/pin-setup') {
    page = const PinSetupPage();
  } else if (name == '/settings/pin-lock') {
    page = const PinLockPage();
  } else if (name == '/settings/sessions') {
    page = const ActiveSessionsPage();
  } else if (name == '/settings/help') {
    page = const HelpSupportPage();
  } else {
    page = const HomeScreen();
  }

  return MaterialPageRoute(builder: (_) => page, settings: settings);
}
