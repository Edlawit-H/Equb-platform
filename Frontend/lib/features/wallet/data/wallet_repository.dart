import 'package:dio/dio.dart';

class WalletRepository {
  final Dio _dio;

  WalletRepository(this._dio);

  Future<Map<String, dynamic>> getWallet() async {
    final res = await _dio.get('/users/me/wallet');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> topUp(double amount) async {
    final res = await _dio.post('/users/me/wallet/topup', data: {'amount': amount});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTransactions({Map<String, dynamic>? filters}) async {
    final res = await _dio.get('/transactions', queryParameters: filters);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTransactionById(String id) async {
    final res = await _dio.get('/transactions/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTransactionStats() async {
    final res = await _dio.get('/transactions/stats');
    return res.data as Map<String, dynamic>;
  }
}
