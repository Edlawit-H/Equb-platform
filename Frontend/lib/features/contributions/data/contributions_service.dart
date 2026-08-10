import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class ContributionsService {
  final Dio _dio = createDioClient();

  Future<Map<String, dynamic>> getContributions({String? groupId, String? status, int page = 1}) async {
    final res = await _dio.get('/contributions', queryParameters: {
      if (groupId != null) 'group_id': groupId,
      if (status != null) 'status': status,
      'page': page,
    });
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getPending() async {
    final res = await _dio.get('/contributions/pending');
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getOverdue() async {
    final res = await _dio.get('/contributions/overdue');
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getStats() async {
    final res = await _dio.get('/contributions/stats');
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getById(String id) async {
    final res = await _dio.get('/contributions/$id');
    return res.data['data'];
  }

  Future<Map<String, dynamic>> pay(String groupId, int cycleNumber) async {
    final res = await _dio.post('/contributions', data: {
      'group_id': groupId,
      'cycle_number': cycleNumber,
    });
    return res.data['data'];
  }
}
