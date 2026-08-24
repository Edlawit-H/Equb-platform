import 'package:dio/dio.dart';
import 'package:equb_app/core/network/dio_client.dart';

class GroupService {
  final Dio _dio;

  GroupService({Dio? dio}) : _dio = dio ?? createDioClient();

  Future<Map<String, dynamic>> createGroup({
    required String groupName,
    required int contribution,
    required int duration,
    required int maxMembers,
    DateTime? startDate,
    String? description,
  }) async {
    try {
      final body = <String, dynamic>{
        "group_name": groupName,
        "contribution_amount": contribution,
        "max_members": maxMembers,
        "cycle_duration": duration,
      };
      if (startDate != null) {
        body["start_date"] = startDate.toIso8601String().split("T")[0];
      }
      if (description != null && description.isNotEmpty) {
        body["description"] = description;
      }

      final response = await _dio.post('/groups', data: body);
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(msg ?? e.message ?? 'Failed to create group');
    }
  }

  Future<Map<String, dynamic>> getGroups() async {
    try {
      final response = await _dio.get(
        '/groups',
        options: Options(headers: {'Cache-Control': 'no-cache'}),
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(msg ?? e.message ?? 'Failed to fetch groups');
    }
  }

  Future<Map<String, dynamic>> joinGroup(String inviteCodeOrId) async {
    try {
      final isUuid = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(inviteCodeOrId);

      final path = isUuid
          ? '/groups/$inviteCodeOrId/join'
          : '/groups/join';

      final data = isUuid ? null : {"invitation_code": inviteCodeOrId.trim()};

      final response = await _dio.post(path, data: data);
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(msg ?? e.message ?? 'Failed to join group');
    }
  }

  Future<Map<String, dynamic>> getGroupById(String groupId) async {
    try {
      final response = await _dio.get('/groups/$groupId');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(msg ?? e.message ?? 'Failed to get group');
    }
  }

  Future<Map<String, dynamic>> getGroupMembers(String groupId) async {
    try {
      final response = await _dio.get('/groups/$groupId/members');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(msg ?? e.message ?? 'Failed to get group members');
    }
  }

  Future<Map<String, dynamic>> startGroup(String groupId) async {
    try {
      final response = await _dio.post('/groups/$groupId/start');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(msg ?? e.message ?? 'Failed to start group');
    }
  }

  Future<Map<String, dynamic>> leaveGroup(String groupId) async {
    try {
      final response = await _dio.post('/groups/$groupId/leave');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(msg ?? e.message ?? 'Failed to leave group');
    }
  }

  Future<Map<String, dynamic>> updateGroup(String groupId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/groups/$groupId', data: data);
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(msg ?? e.message ?? 'Failed to update group');
    }
  }

  Future<Map<String, dynamic>> deleteGroup(String groupId) async {
    try {
      final response = await _dio.delete('/groups/$groupId');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(msg ?? e.message ?? 'Failed to delete group');
    }
  }
}