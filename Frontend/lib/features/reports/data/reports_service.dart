import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

class ReportsService {
  final Dio _dio = createDioClient();
  static const _storage = FlutterSecureStorage();

  Future<Map<String, dynamic>> getDashboard() async {
    final res = await _dio.get('/reports/dashboard');
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getUserSummary() async {
    final res = await _dio.get('/reports/user-summary');
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getGroupSummary(String groupId) async {
    final res = await _dio
        .get('/reports/group-summary', queryParameters: {'group_id': groupId});
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    final res = await _dio.get('/reports/analytics');
    return res.data['data'];
  }

  /// Returns an authenticated URL the browser can open directly to download the file.
  /// Token is passed as query param since browser <a> tags can't set Authorization headers.
  Future<String> getExportUrl(String path) async {
    final token = await _storage.read(key: 'access_token');
    final separator = path.contains('?') ? '&' : '?';
    return '${ApiConstants.baseUrl}$path${separator}token=${Uri.encodeComponent(token ?? '')}';
  }

  Future<String> getGroupExportUrl(String groupId, {required bool excel}) {
    final path =
        excel ? '/reports/export/group/excel' : '/reports/export/group/pdf';
    return getExportUrl('$path?group_id=${Uri.encodeComponent(groupId)}');
  }
}
