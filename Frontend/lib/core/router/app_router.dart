import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/reports/presentation/pages/home_dashboard_page.dart';
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
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/language_page.dart';
import '../../features/settings/presentation/pages/pin_setup_page.dart';
import '../../features/settings/presentation/pages/pin_lock_page.dart';
import '../../features/settings/presentation/pages/active_sessions_page.dart';
import '../../features/settings/presentation/pages/help_support_page.dart';

Route<dynamic> onGenerateAppRoute(RouteSettings settings) {
  final name = settings.name ?? '/home';
  final args = settings.arguments;

  Widget page;

  if (name == '/' || name == '/splash') {
    page = const SplashPage();
  } else if (name == '/home') {
    page = const HomeDashboardPage();
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
    page = PayContributionPage(contribution: (args as Map<String, dynamic>?) ?? {});
  } else if (name.startsWith('/contributions/')) {
    final id = name.replaceFirst('/contributions/', '');
    page = ContributionDetailPage(contributionId: id);
  } else if (name == '/payouts/schedule') {
    page = const PayoutSchedulePage();
  } else if (name == '/payouts/history') {
    page = const PayoutHistoryPage();
  } else if (name.startsWith('/payouts/')) {
    final id = name.replaceFirst('/payouts/', '');
    page = PayoutDetailPage(payoutId: id);
  } else if (name == '/reports') {
    page = const AnalyticsDashboardPage();
  } else if (name == '/reports/export') {
    page = const ExportReportPage();
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
  } else if (name == '/profile' || name == '/change-password' || name == '/notifications/settings') {
    page = Scaffold(
      appBar: AppBar(title: Text(name.replaceAll('/', ' ').toUpperCase(), style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold))),
      body: Center(child: Text('$name Page (Etsub\'s Module)', style: const TextStyle(fontFamily: 'Poppins', fontSize: 16))),
    );
  } else {
    page = const HomeDashboardPage();
  }

  return MaterialPageRoute(builder: (_) => page, settings: settings);
}
