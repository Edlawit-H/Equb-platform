import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:equb_app/core/constants/api_constants.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();
  static String get baseUrl => ApiConstants.authBaseUrl;

  /// Saves access token using the same key that dio_client.dart reads ('access_token')
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }


static Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  
  static Future<Map<String, dynamic>> login(
      String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone_number": phone,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await saveToken(data['data']['accessToken']);
        await saveRefreshToken(data['data']['refreshToken']);
        return data;
      }

      throw Exception(data['message'] ?? 'Login failed');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception(
        'Unable to reach the server. Check that the backend is running on port 5000.',
      );
    }
  }
  static Future<Map<String, dynamic>> getUserData() async {
    final token = await _storage.read(key: 'access_token');
    final response = await http.get(
      Uri.parse("$baseUrl/user"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    return jsonDecode(response.body);
  }

static Future<Map<String, dynamic>> register({
  required String phone,
}) async {
  final response = await http.post(
    Uri.parse("$baseUrl/register"),
    headers: {
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "phone_number": phone,
    }),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200) {
    return data;
  } else {
    throw Exception(data["message"]);
  }
}

static Future<Map<String, dynamic>> verifyRegistrationOTP({
  required String phone,
  required String otp,
  required String password,
  required String fullName,
}) async {
  final response = await http.post(
    Uri.parse("$baseUrl/verify-otp"),
    headers: {
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "phone_number": phone,
      "otp_code": otp,
      "password": password,
      "full_name": fullName,
    }),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode >= 200 && response.statusCode < 300) {
   await saveToken(data['data']['token']);
    await saveRefreshToken(data['data']['refreshToken']);
   return data;
  } else {
    throw Exception(data["message"] ?? "OTP verification failed");
  }
}

static Future<Map<String, dynamic>> resendRegistrationOTP({
  required String phone,
}) async {
  final response = await http.post(
    Uri.parse("$baseUrl/resend-otp"),
    headers: {
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "phone_number": phone,
    }),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode >= 200 && response.statusCode < 300) {
    return data;
  } else {
    throw Exception(
      data["message"] ?? "Failed to resend OTP",
    );
  }
}

static Future<Map<String, dynamic>> requestPasswordReset({
  required String phone,
}) async {
  final response = await http.post(
    Uri.parse("$baseUrl/forgot-password"),
    headers: {
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "phone_number": phone,
    }),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode >= 200 &&
      response.statusCode < 300) {
    return data;
  } else {
    throw Exception(
      data["message"] ?? "Failed to send reset OTP",
    );
  }
}
static Future<Map<String, dynamic>> resetPassword({
  required String phone,
  required String otp,
  required String newPassword,
}) async {
  final response = await http.post(
    Uri.parse("$baseUrl/reset-password"),
    headers: {
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "phone_number": phone,
      "otp_code": otp,
      "new_password": newPassword,
    }),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode >= 200 &&
      response.statusCode < 300) {
    return data;
  } else {
    throw Exception(
      data["message"] ?? "Password reset failed",
    );
  }
}
}