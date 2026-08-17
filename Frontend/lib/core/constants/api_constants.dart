import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String auth = '/auth';
  static const String users = '/users';
  static const String groups = '/groups';
  static const String contributions = '/contributions';
  static const String payouts = '/payouts';
  static const String transactions = '/transactions';
  static const String notifications = '/notifications';
  static const String reports = '/reports';
  static const String admin = '/admin';

  /// Backend API base URL. Override at build time with --dart-define=API_BASE_URL=...
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    return kIsWeb
        ? 'http://localhost:5000/api/v1'
        : 'http://10.0.2.2:5000/api/v1';
  }

  static String get authBaseUrl => '$baseUrl/auth';
}
