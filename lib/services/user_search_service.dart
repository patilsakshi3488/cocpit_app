import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/search_user.dart';

class UserSearchService {
  static Future<List<SearchUser>> searchUsers({
    required String query,
    required String token,
  }) async {
    // Manually construct the full URL since we are using http.get directly, not ApiClient
    final uri = Uri.parse(
      "${ApiConfig.baseUrl}${ApiConfig.searchUsers}?q=${Uri.encodeQueryComponent(query)}",
    );

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => SearchUser.fromJson(e)).toList();
    } else {
      throw Exception("Failed to search users");
    }
  }
}
