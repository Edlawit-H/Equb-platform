import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:equb_app/core/constants/api_constants.dart';

class ProfileService {
  static const _storage = FlutterSecureStorage();
  static String get baseUrl => ApiConstants.baseUrl;

  static Future<String?> _getToken() async {
    return await _storage.read(key: 'access_token');
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/users/me"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Failed to load profile");
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    String? email,
  }) async {
    final token = await _getToken();

    final body = <String, dynamic>{
      "full_name": fullName,
    };
    if (email != null && email.trim().isNotEmpty && email != '—' && email != 'null') {
      body["email"] = email.trim();
    }

    final response = await http.patch(
      Uri.parse("$baseUrl/users/me"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    final resBody = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return resBody;
    }
    throw Exception(resBody['message'] ?? "Failed to update profile");
  }

  static Future<Map<String, dynamic>> requestPhoneChangeOTP({
    required String newPhone,
  }) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/users/me/phone/send-otp"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "phone_number": newPhone.trim(),
      }),
    );

    final resBody = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return resBody;
    }
    throw Exception(resBody['message'] ?? "Failed to send OTP");
  }

  static Future<Map<String, dynamic>> verifyPhoneChangeOTP({
    required String newPhone,
    required String otp,
  }) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/users/me/phone/verify-otp"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "phone_number": newPhone.trim(),
        "otp": otp.trim(),
      }),
    );

    final resBody = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return resBody;
    }
    throw Exception(resBody['message'] ?? "Failed to verify OTP");
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await _getToken();

    final response = await http.patch(
      Uri.parse("$baseUrl/users/me/password"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "current_password": currentPassword,
        "new_password": newPassword,
      }),
    );

    final resBody = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return resBody;
    }
    throw Exception(resBody['message'] ?? "Failed to change password");
  }
}