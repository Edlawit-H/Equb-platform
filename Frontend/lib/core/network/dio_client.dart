import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:equb_app/core/constants/api_constants.dart';

const _storage = FlutterSecureStorage();

// Shared Future to prevent duplicate refresh token requests when multiple 401s occur simultaneously
Future<String?>? _refreshTokenFuture;

Future<String?> _performTokenRefresh() async {
  try {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    // Use a clean Dio instance with no interceptors to avoid recursive loops
    final refreshDio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    final response = await refreshDio.post(
      '/auth/refresh-token',
      data: {
        'refreshToken': refreshToken,
        'refresh_token': refreshToken,
      },
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data;
      final newAccessToken = data['data']?['accessToken'] ??
          data['data']?['token'] ??
          data['accessToken'] ??
          data['token'];

      final newRefreshToken = data['data']?['refreshToken'] ??
          data['data']?['refresh_token'] ??
          data['refreshToken'] ??
          data['refresh_token'];

      if (newAccessToken != null) {
        await _storage.write(key: 'access_token', value: newAccessToken.toString());
        if (newRefreshToken != null) {
          await _storage.write(key: 'refresh_token', value: newRefreshToken.toString());
        }
        return newAccessToken.toString();
      }
    }
  } catch (e) {
    // If refresh token fails (expired or invalid), clear stored tokens
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
  return null;
}

Dio createDioClient() {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(QueuedInterceptorsWrapper(
    onRequest: (options, handler) async {
      try {
        final token = await _storage.read(key: 'access_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } catch (_) {}
      handler.next(options);
    },
    onError: (error, handler) async {
      final statusCode = error.response?.statusCode;
      final path = error.requestOptions.path;
      final isAuthEndpoint = path.contains('/auth/login') ||
          path.contains('/auth/register') ||
          path.contains('/auth/refresh-token') ||
          path.contains('/auth/verify-otp') ||
          path.contains('/auth/forgot-password') ||
          path.contains('/auth/reset-password');

      final alreadyRetried = error.requestOptions.extra['_retry'] == true;

      if (statusCode == 401 && !isAuthEndpoint && !alreadyRetried) {
        // Mark request as retried to avoid infinite loops
        error.requestOptions.extra['_retry'] = true;

        // Synchronize token refresh across concurrent requests
        _refreshTokenFuture ??= _performTokenRefresh().whenComplete(() {
          _refreshTokenFuture = null;
        });

        final newAccessToken = await _refreshTokenFuture;

        if (newAccessToken != null) {
          error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          try {
            final retryResponse = await dio.fetch(error.requestOptions);
            return handler.resolve(retryResponse);
          } on DioException catch (retryError) {
            return handler.next(retryError);
          }
        }
      }

      handler.next(error);
    },
  ));

  return dio;
}
