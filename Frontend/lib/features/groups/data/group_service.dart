import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GroupService {
  final String baseUrl = "http://localhost:3000/api/v1";
  
  Future<Map<String, dynamic>> createGroup({
     required String groupName,
  required int contribution,
  required int duration,
  required int maxMembers,
  DateTime? startDate,
  String? description,

  }) async {

      final prefs = await SharedPreferences.getInstance();
      final token =  prefs.getString("token");
        
    
    final body = {
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

    final response = await http.post(
      Uri.parse("$baseUrl/groups"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    return jsonDecode(response.body);
  }

    Future<Map<String, dynamic>> getGroups()async{
        final prefs = await SharedPreferences.getInstance();
        final token =  prefs.getString("token");

        final response = await http.get(
        Uri.parse("$baseUrl/groups"),
        headers: {"Authorization": "Bearer $token",
                  "Cache-Control": "no-cache",}
        );
return jsonDecode(response.body);
    }
}