import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:equb_app/core/network/dio_client.dart';
import 'package:equb_app/core/constants/api_constants.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();
  static final Dio _dio = createDioClient();

  static String get baseUrl => ApiConstants.authBaseUrl;

  /// Saves access token using the same key that dio_client.dart reads ('access_token')
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  static Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> login(
      String phone, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          "phone_number": phone,
          "password": password,
        },
      );

      final data = _asMap(response.data);

      if (data['data'] != null && data['data'] is Map) {
        final token = data['data']['accessToken'] ?? data['data']['token'];
        if (token != null) {
          await saveToken(token.toString());
        }
        final refreshToken = data['data']['refreshToken'];
        if (refreshToken != null) {
          await saveRefreshToken(refreshToken.toString());
        }
      }

      return data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final resData = e.response?.data;
        if (resData is Map && resData['message'] != null) {
          throw Exception(resData['message']);
        }
      }
      throw Exception(
        e.message ??
            'Unable to reach the server. Check that the backend is running on port 5000.',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> getUserData() async {
    try {
      final response = await _dio.get('/auth/profile');
      return _asMap(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(msg ?? e.message ?? 'Failed to fetch user data');
    }
  }

  static Future<Map<String, dynamic>> register({
    required String phone,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          "phone_number": phone,
        },
      );
      return _asMap(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(msg ?? e.message ?? 'Failed to register');
    }
  }

  static Future<Map<String, dynamic>> verifyRegistrationOTP({
    required String phone,
    required String otp,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/verify-otp',
        data: {
          "phone_number": phone,
          "otp_code": otp,
          "password": password,
          "full_name": fullName,
        },
      );

      final data = _asMap(response.data);

      if (data['data'] != null && data['data'] is Map) {
        final token = data['data']['token'] ?? data['data']['accessToken'];
        if (token != null) {
          await saveToken(token.toString());
        }
        final refreshToken = data['data']['refreshToken'];
        if (refreshToken != null) {
          await saveRefreshToken(refreshToken.toString());
        }
      }

      return data;
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(msg ?? e.message ?? 'OTP verification failed');
    }
  }

  static Future<Map<String, dynamic>> resendRegistrationOTP({
    required String phone,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/resend-otp',
        data: {
          "phone_number": phone,
        },
      );
      return _asMap(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(msg ?? e.message ?? 'Failed to resend OTP');
    }
  }

  static Future<Map<String, dynamic>> requestPasswordReset({
    required String phone,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password',
        data: {
          "phone_number": phone,
        },
      );
      return _asMap(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(msg ?? e.message ?? 'Failed to send reset OTP');
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/reset-password',
        data: {
          "phone_number": phone,
          "otp_code": otp,
          "new_password": newPassword,
        },
      );
      return _asMap(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(msg ?? e.message ?? 'Password reset failed');
    }
  }

  static Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        '/auth/refresh-token',
        data: {"refreshToken": refreshToken},
      );
      return _asMap(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(msg ?? e.message ?? 'Failed to refresh token');
    }
  }

  static Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}