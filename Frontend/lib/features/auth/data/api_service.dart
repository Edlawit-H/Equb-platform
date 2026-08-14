import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
 // static const _storage = FlutterSecureStorage(); 
  static const String baseUrl = "http://localhost:3000/api/v1/auth";
  
  static Future<void> saveToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('token', token);
}


static Future<void> saveRefreshToken(String refreshToken) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('refreshToken', refreshToken);
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
      }),);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {   
    await saveToken(data['data']['accessToken']);
    await saveRefreshToken(data['data']['refreshToken']);
    
    return data;
    } else {
      throw  Exception(data["message"]);
    }
  } catch (e){
  throw Exception(e.toString());
}

}
  static Future<Map<String, dynamic>> getUserData() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
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