import 'package:dio/dio.dart';

class NotificationsRepository {
  final Dio _dio;

  NotificationsRepository(this._dio);

  Future<Map<String, dynamic>> getNotifications({int page = 1}) async {
    final res = await _dio.get('/notifications', queryParameters: {'page': page});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getUnreadCount() async {
    final res = await _dio.get('/notifications/unread');
    return res.data as Map<String, dynamic>;
  }

  Future<void> markAsRead(String id) async {
    await _dio.patch('/notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _dio.patch('/notifications/read-all');
  }

  Future<Map<String, dynamic>> getSettings() async {
    final res = await _dio.get('/notifications/settings');
    return res.data as Map<String, dynamic>;
  }

  Future<void> updateSettings(Map<String, dynamic> body) async {
    await _dio.patch('/notifications/settings', data: body);
  }
}
