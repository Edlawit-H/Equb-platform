import 'package:dio/dio.dart';

class ReportsRepository {
  final Dio _dio;

  ReportsRepository(this._dio);

  Future<Map<String, dynamic>> getDashboard() async {
    final res = await _dio.get('/reports/dashboard');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getUserSummary({Map<String, dynamic>? filters}) async {
    final res = await _dio.get('/reports/user-summary', queryParameters: filters);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getGroupSummary(String groupId) async {
    final res = await _dio.get('/reports/group-summary', queryParameters: {'group_id': groupId});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    final res = await _dio.get('/reports/analytics');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> exportPdf() async {
    final res = await _dio.get('/reports/export/pdf');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> exportExcel() async {
    final res = await _dio.get('/reports/export/excel');
    return res.data as Map<String, dynamic>;
  }
}
