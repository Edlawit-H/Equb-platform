import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class NotificationsRepository {
  final Dio _dio;

  NotificationsRepository([Dio? dio]) : _dio = dio ?? createDioClient();

  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
    String? type,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (isRead != null) queryParams['is_read'] = isRead;
    if (type != null && type.isNotEmpty) queryParams['type'] = type;

    final res = await _dio.get('/notifications', queryParameters: queryParams);
    return res.data is Map ? Map<String, dynamic>.from(res.data) : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getUnreadCount() async {
    final res = await _dio.get('/notifications/unread');
    return res.data is Map ? Map<String, dynamic>.from(res.data) : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getNotificationById(String id) async {
    final res = await _dio.get('/notifications/$id');
    return res.data is Map ? Map<String, dynamic>.from(res.data) : <String, dynamic>{};
  }

  Future<void> markAsRead(String id) async {
    await _dio.patch('/notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _dio.patch('/notifications/read-all');
  }

  Future<void> deleteNotification(String id) async {
    await _dio.delete('/notifications/$id');
  }

  Future<Map<String, dynamic>> getSettings() async {
    final res = await _dio.get('/notifications/settings');
    return res.data is Map ? Map<String, dynamic>.from(res.data) : <String, dynamic>{};
  }

  Future<void> updateSettings(Map<String, dynamic> body) async {
    await _dio.patch('/notifications/settings', data: body);
  }
}
