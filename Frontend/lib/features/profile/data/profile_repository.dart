import 'package:dio/dio.dart';

class ProfileRepository {
  final Dio _dio;

  ProfileRepository(this._dio);

  Future<Map<String, dynamic>> getProfile() async {
    final res = await _dio.get('/auth/profile');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) async {
    final res = await _dio.put('/auth/profile', data: body);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(filePath),
    });
    final res = await _dio.post('/auth/upload-avatar', data: formData);
    return res.data as Map<String, dynamic>;
  }

  Future<void> changePassword(Map<String, dynamic> body) async {
    await _dio.put('/auth/change-password', data: body);
  }
}
