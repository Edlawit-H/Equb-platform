import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class SessionsService {
  final Dio _dio = createDioClient();

  Future<List<dynamic>> getSessions() async {
    final res = await _dio.get('/users/me/sessions');
    return res.data['data']['sessions'] ?? [];
  }

  Future<void> revokeSession(String tokenId) async {
    await _dio.delete('/users/me/sessions/$tokenId');
  }

  Future<void> revokeAllOthers() async {
    await _dio.delete('/users/me/sessions');
  }
}
