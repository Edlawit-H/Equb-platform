import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage();

Dio createDioClient() {
  final defaultBaseUrl = kIsWeb ? 'http://localhost:5000/api/v1' : 'http://10.0.2.2:5000/api/v1';
  final dio = Dio(BaseOptions(
    baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: ''),
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  if (dio.options.baseUrl.isEmpty) {
    dio.options.baseUrl = defaultBaseUrl;
  }

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      try {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } catch (_) {}
      handler.next(options);
    },
    onError: (error, handler) async {
      handler.next(error);
    },
  ));

  return dio;
}
