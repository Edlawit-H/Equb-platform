import 'package:dio/dio.dart';

class PayoutsRepository {
  final Dio _dio;

  PayoutsRepository(this._dio);

  Future<Map<String, dynamic>> getMyPayouts() async {
    final res = await _dio.get('/payouts');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPayoutById(String id) async {
    final res = await _dio.get('/payouts/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSchedule() async {
    final res = await _dio.get('/payouts/schedule');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getGroupPayouts(String groupId) async {
    final res = await _dio.get('/groups/$groupId/payouts');
    return res.data as Map<String, dynamic>;
  }
}
