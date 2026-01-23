import 'dart:convert';
import 'package:cocpit_app/services/api_client.dart';
import '../models/public_user.dart';

class PublicUserService {
  static Future<PublicUser> getUserProfile(String userId) async {
    // Attempt: /profile/:id (Aligned with ProfileService)
    try {
      final url = "/profile/$userId";
      print("🚀 Fetching public profile: $url");

      final response = await ApiClient.get(url);

      print("📥 Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return PublicUser.fromJson(data);
        } catch (e) {
          print("❌ JSON Parse Error: $e");
          print("📄 Raw Body: ${response.body}");
          rethrow;
        }
      } else {
        print("❌ API Error: ${response.body}");
        throw Exception("Failed to load profile (${response.statusCode})");
      }
    } catch (e) {
      print("❌ PublicUserService exception: $e");
      throw Exception("Failed to load public profile: $e");
    }
  }
}
