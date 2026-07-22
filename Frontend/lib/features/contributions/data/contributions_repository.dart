import 'package:dio/dio.dart';

class ContributionsRepository {
  final Dio _dio;

  ContributionsRepository(this._dio);

  Future<Map<String, dynamic>> payContribution(Map<String, dynamic> body) async {
    final res = await _dio.post('/contributions', data: body);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getContributions({Map<String, dynamic>? filters}) async {
    final res = await _dio.get('/contributions', queryParameters: filters);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPending() async {
    final res = await _dio.get('/contributions/pending');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getOverdue() async {
    final res = await _dio.get('/contributions/overdue');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> bulkPay(Map<String, dynamic> body) async {
    final res = await _dio.post('/contributions/bulk', data: body);
    return res.data as Map<String, dynamic>;
  }
}
