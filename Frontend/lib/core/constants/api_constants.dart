import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String _productionUrl = 'https://equb-backend-t6h8.onrender.com/api/v1';

  /// Override at build time: flutter build apk --dart-define=API_BASE_URL=https://...
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;

    if (kDebugMode) {
      return kIsWeb
          ? 'http://localhost:5000/api/v1'
          : 'http://10.0.2.2:5000/api/v1';
    }

    return _productionUrl;
  }

  static String get authBaseUrl => '$baseUrl/auth';
}
