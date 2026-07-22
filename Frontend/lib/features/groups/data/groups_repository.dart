import 'package:dio/dio.dart';

class GroupsRepository {
  final Dio _dio;

  GroupsRepository(this._dio);

  Future<Map<String, dynamic>> createGroup(Map<String, dynamic> body) async {
    final res = await _dio.post('/groups', data: body);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMyGroups() async {
    final res = await _dio.get('/groups');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getGroupById(String id) async {
    final res = await _dio.get('/groups/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> joinGroup(String invitationCode) async {
    final res = await _dio.post('/groups/join', data: {'invitation_code': invitationCode});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> startGroup(String id) async {
    final res = await _dio.post('/groups/$id/start');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getGroupDashboard(String id) async {
    final res = await _dio.get('/groups/$id/dashboard');
    return res.data as Map<String, dynamic>;
  }
}
