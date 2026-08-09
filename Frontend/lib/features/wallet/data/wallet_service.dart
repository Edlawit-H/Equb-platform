import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class WalletService {
  final Dio _dio = createDioClient();

  Future<Map<String, dynamic>> getWallet() async {
    final res = await _dio.get('/transactions/wallet');
    return res.data['data'];
  }

  Future<Map<String, dynamic>> topUp(double amount) async {
    final res = await _dio.post('/transactions/top-up', data: {'amount': amount});
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getTransactions({
    String? type,
    String? groupId,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get('/transactions', queryParameters: {
      if (type != null) 'type': type,
      if (groupId != null) 'group_id': groupId,
      'page': page,
      'limit': limit,
    });
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getTransactionById(String id) async {
    final res = await _dio.get('/transactions/$id');
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getTransactionStats() async {
    final res = await _dio.get('/transactions/stats');
    return res.data['data'];
  }
}
