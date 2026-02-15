import 'dart:convert';
import 'package:cocpit_app/services/api_client.dart';
import '../models/public_user.dart';

class PublicUserService {
  static Future<PublicUser> getUserProfile(String userId) async {
    // Attempt: /users/:id (Based on ApiConfig)
    try {
      final url = "/users/$userId";

      final response = await ApiClient.get(url);


      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          // If the backend returns { "user": ... } or straight object
          return PublicUser.fromJson(data);
        } catch (e) {
          rethrow;
        }
      } else {
        throw Exception("Failed to load profile (${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Failed to load public profile: $e");
    }
  }
}
