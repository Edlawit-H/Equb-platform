import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class ContributionsService {
  final Dio _dio = createDioClient();

  Future<Map<String, dynamic>> getContributions(
      {String? groupId, String? status, int page = 1}) async {
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

  Future<List<Map<String, dynamic>>> getPendingContributions() async {
    try {
      final res = await getPending();
      if (res['contributions'] != null && res['contributions'] is List) {
        return List<Map<String, dynamic>>.from(res['contributions']);
      }
      return [];
    } catch (_) {
      return [];
    }
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

  Future<Map<String, dynamic>> getGroupContributions(String groupId,
      {int page = 1}) async {
    final res = await _dio.get(
      '/groups/$groupId/contributions',
      queryParameters: {'page': page},
    );
    return res.data['data'];
  }

  Future<Map<String, dynamic>> pay(String groupId, int cycleNumber) async {
    try {
      final res = await _dio.post('/contributions', data: {
        'group_id': groupId,
        'cycle_number': cycleNumber,
      });
      return res.data['data'];
    } on DioException catch (e) {
      final body = e.response?.data;
      final msg = body is Map ? body['message']?.toString() : null;
      throw Exception(_friendlyContributionError(msg));
    }
  }

  static String _friendlyContributionError(String? msg) {
    if (msg == null) return 'Payment failed. Please try again.';
    final lower = msg.toLowerCase();
    if (lower.contains('already been paid') || lower.contains('already paid')) {
      return 'You have already contributed for this cycle.';
    }
    if (lower.contains('insufficient')) {
      return 'Your wallet balance is too low. Please top up and try again.';
    }
    if (lower.contains('not active') || lower.contains('group is not')) {
      return 'This group is not active. Contributions cannot be made right now.';
    }
    if (lower.contains('cannot pay for cycle')) {
      return 'You cannot pay for a cycle that has not started yet.';
    }
    if (lower.contains('not an active member')) {
      return 'You are not an active member of this group.';
    }
    if (lower.contains('not found')) {
      return 'Contribution record not found. Please refresh and try again.';
    }
    return msg;
  }
  Future<Map<String, dynamic>> payContribution({
    required String groupId,
    required int cycleNumber,
    String? paymentMethod,
    String? contributionId,
    double? amount,
  }) async {
    return await pay(groupId, cycleNumber);
  }
}
