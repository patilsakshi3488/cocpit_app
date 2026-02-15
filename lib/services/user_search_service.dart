import 'dart:convert';
import 'package:cocpit_app/services/api_client.dart';
import 'package:cocpit_app/config/api_config.dart';
import 'package:cocpit_app/models/search_user.dart';

class UserSearchService {
  static Future<List<SearchUser>> searchUsers({
    required String query,
    required String token, // Optional now, ApiClient handles it
  }) async {
    final response = await ApiClient.get(
      "${ApiConfig.searchUsers}?q=${Uri.encodeQueryComponent(query)}",
    );

    if (response.statusCode == 200) {
      final dynamic decoded = json.decode(response.body);
      final List data = (decoded is Map && decoded.containsKey('data'))
          ? decoded['data']
          : (decoded is List ? decoded : []);

      return data.map((e) => SearchUser.fromJson(e)).toList();
    } else {
      throw Exception("Failed to search users");
    }
  }
}
