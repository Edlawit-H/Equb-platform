import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  static const String baseUrl =
      "http://localhost:3000/api/v1"; // Android Emulator

  static Future<Map<String, dynamic>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) {
      throw Exception("No token found");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/auth/profile"),
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
  required String email,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("token");

  final response = await http.put(
    Uri.parse("$baseUrl/auth/profile"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({
      "full_name": fullName,
      "email": email,
    }),
  );

  return jsonDecode(response.body);
}
}