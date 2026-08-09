import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class ReportsService {
  final Dio _dio = createDioClient();

  Future<Map<String, dynamic>> getDashboard() async {
    final res = await _dio.get('/reports/dashboard');
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getUserSummary() async {
    final res = await _dio.get('/reports/user-summary');
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getGroupSummary(String groupId) async {
    final res = await _dio.get('/reports/group-summary', queryParameters: {'group_id': groupId});
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    final res = await _dio.get('/reports/analytics');
    return res.data['data'];
  }

  Future<Map<String, dynamic>> exportPdf() async {
    final res = await _dio.get('/reports/export/pdf');
    return res.data['data'];
  }

  Future<void> exportExcel() async {
    await _dio.get('/reports/export/excel');
  }
}
