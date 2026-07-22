import 'package:dio/dio.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<Map<String, dynamic>> register(Map<String, dynamic> body) async {
    final res = await _dio.post('/auth/register', data: body);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login(Map<String, dynamic> body) async {
    final res = await _dio.post('/auth/login', data: body);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyOtp(Map<String, dynamic> body) async {
    final res = await _dio.post('/auth/verify-otp', data: body);
    return res.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await _dio.post('/auth/logout');
  }

  Future<Map<String, dynamic>> refreshToken(String token) async {
    final res = await _dio.post('/auth/refresh-token', data: {'refresh_token': token});
    return res.data as Map<String, dynamic>;
  }

  Future<void> forgotPassword(String contact) async {
    await _dio.post('/auth/forgot-password', data: {'contact': contact});
  }

  Future<void> resetPassword(Map<String, dynamic> body) async {
    await _dio.post('/auth/reset-password', data: body);
  }
}
