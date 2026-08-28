import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class PayoutsService {
  final Dio _dio = createDioClient();

  Future<Map<String, dynamic>> getMyPayouts(
      {String? status, int page = 1}) async {
    final res = await _dio.get('/payouts', queryParameters: {
      if (status != null) 'status': status,
      'page': page,
    });
    return _unwrapData(res.data);
  }

  Future<Map<String, dynamic>> getHistory({int page = 1}) async {
    final res =
        await _dio.get('/payouts/history', queryParameters: {'page': page});
    return _unwrapData(res.data);
  }

  Future<Map<String, dynamic>> getSchedule() async {
    final res = await _dio.get('/payouts/schedule');
    return _unwrapData(res.data);
  }

  Future<Map<String, dynamic>> getById(String id) async {
    final res = await _dio.get('/payouts/$id');
    return _unwrapData(res.data);
  }

  Future<Map<String, dynamic>> getGroupPayouts(String groupId,
      {int page = 1}) async {
    final res = await _dio
        .get('/groups/$groupId/payouts', queryParameters: {'page': page});
    return _unwrapData(res.data);
  }

  Future<Map<String, dynamic>> approvePayout(String payoutId) async {
    final res = await _dio.post('/payouts/$payoutId/approve');
    return _unwrapData(res.data);
  }

  Future<Map<String, dynamic>> rejectPayout(String payoutId) async {
    final res = await _dio.post('/payouts/$payoutId/reject');
    return _unwrapData(res.data);
  }

  Map<String, dynamic> _unwrapData(dynamic data) {
    if (data is Map) {
      if (data['data'] is Map) {
        return Map<String, dynamic>.from(data['data']);
      }
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }
}
