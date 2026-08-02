import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
class ApiService {
  static const String baseUrl = "http://localhost:3000/api/v1/auth";
  
  static Future<void> saveToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('token', token);
}

  
  static Future<Map<String, dynamic>> login(
      String phone, String password) async {
    try {final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "phone_number": phone,
        "password": password,
      }),);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {   
    await saveToken(data['data']['token']);
    return data;
    } else {
      throw  Exception(data["message"]);
    }
  } catch (e) {
   throw Exception("Unable to connect to the server.");
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
}