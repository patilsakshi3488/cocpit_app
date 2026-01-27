import 'dart:convert';

import 'package:cocpit_app/config/api_config.dart';
import 'package:cocpit_app/services/api_client.dart';
import 'package:cocpit_app/services/secure_storage.dart';
import 'package:cocpit_app/services/socket_service.dart';

class AuthService {
  /// ================= REGISTER =================
  /// Website behavior:
  /// - Creates user
  /// - DOES NOT create session
  /// - User must login after signup
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String accountType,
  }) async {
    final response = await ApiClient.post(
      ApiConfig.register,
      body: {
        "fullName": fullName,
        "email": email.toLowerCase().trim(),
        "password": password,
        "accountType": accountType,
      },
    );

    return response.statusCode == 201;
  }

  /// ================= LOGIN =================
  /// Website behavior:
  /// - Creates session
  /// - Stores refresh token in DB
  /// - Returns access + refresh tokens
  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.post(
      ApiConfig.login,
      body: {"email": email.toLowerCase().trim(), "password": password},
    );

    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body);

    await AppSecureStorage.saveAccessToken(body["accessToken"]);
    await AppSecureStorage.saveRefreshToken(body["refreshToken"]);

    // Save initial user (will be refreshed by /auth/me)
    if (body["user"] != null) {
      await AppSecureStorage.saveUser(jsonEncode(body["user"]));
    }

    // 🔌 Connect Socket
    SocketService().connect(body["accessToken"]);

    return body;
  }

  /// ================= GET CURRENT USER =================
  /// Single source of truth for user data
  /// Used on:
  /// - App startup
  /// - After login
  /// - Profile refresh
  Future<Map<String, dynamic>?> getMe() async {
    final response = await ApiClient.get(ApiConfig.me);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // 🔥 Always sync latest backend user
      await AppSecureStorage.saveUser(jsonEncode(data));

      return data;
    }

    return null;
  }

  /// ================= REFRESH ACCESS TOKEN =================
  /// Called automatically by ApiClient on 401
  Future<String?> refreshAccessToken() async {
    final refreshToken = await AppSecureStorage.getRefreshToken();
    if (refreshToken == null) return null;

    final response = await ApiClient.post(
      ApiConfig.refresh,
      body: {"refreshToken": refreshToken},
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final newAccessToken = body["accessToken"];

      await AppSecureStorage.saveAccessToken(newAccessToken);
      return newAccessToken;
    }

    // ❌ Refresh failed → session invalid
    await logout();
    return null;
  }

  /// ================= LOGOUT =================
  /// Website behavior:
  /// - Requires access token
  /// - Deletes refresh token row from DB
  /// - Clears cookies (web)
  /// App behavior:
  /// - Same backend call
  /// - Clear secure storage
  Future<void> logout() async {
    try {
      await ApiClient.post(ApiConfig.logout);
    } catch (_) {
      // Even if backend fails, we still logout locally
    }

    await AppSecureStorage.clearAll();
    SocketService().disconnect(); // 🔌 Disconnect socket
  }
}
