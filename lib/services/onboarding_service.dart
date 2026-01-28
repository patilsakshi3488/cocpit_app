import 'dart:convert';
import 'dart:io';
import '../config/api_config.dart';
import 'api_client.dart';

class OnboardingService {
  Future<bool> checkAccountName(String accountName) async {
    try {
      final response = await ApiClient.get(
        "${ApiConfig.checkAccountName}?account_name=$accountName",
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['available'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> completeOnboarding({
    required String accountName,
    required File avatarImage,
  }) async {
    try {
      // Backend expects:
      // - account_name (text field)
      // - image (file field - likely 'file' or 'avatar')
      // Let's check logic: usage of uploadAvatar.any() middleware usually means any field name,
      // but commonly it's "file" or "avatar".
      // Controller uses `req.files[0]`.

      final response = await ApiClient.multipart(
        ApiConfig.completeOnboarding,
        fileField: "avatar", // Common convention, will try "avatar"
        file: avatarImage,
        fields: {"account_name": accountName},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
