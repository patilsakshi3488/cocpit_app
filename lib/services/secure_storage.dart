import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppSecureStorage {
  static const _storage = FlutterSecureStorage();

  // 🔐 TOKENS
  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: 'accessToken', value: token);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: 'refreshToken', value: token);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: 'accessToken');
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refreshToken');
  }

  // 👤 USER DATA (NEW – FIXES ERROR)
  static Future<void> saveUser(String userJson) async {
    await _storage.write(key: 'user', value: userJson);
  }

  static Future<String?> getUser() async {
    return await _storage.read(key: 'user');
  }

  // 🚪 LOGOUT
  static Future<void> clearAll() async {
    // await _storage.deleteAll(); // ❌ Don't wipe everything

    // ✅ Only wipe Authentication & User Data
    // This ensures 'search_history' (and future settings) persist across sessions
    await Future.wait([
      _storage.delete(key: 'accessToken'),
      _storage.delete(key: 'refreshToken'),
      _storage.delete(key: 'user'),
    ]);
  }

  // 🔍 SEARCH HISTORY (USER SPECIFIC)
  static Future<void> saveSearchHistory(String jsonList) async {
    final userId = await getCurrentUserId() ?? 'guest';
    await _storage.write(key: 'search_history_$userId', value: jsonList);
  }

  static Future<String?> getSearchHistory() async {
    final userId = await getCurrentUserId() ?? 'guest';
    return await _storage.read(key: 'search_history_$userId');
  }

  /// 🕵️ Helper to extract ID from stored user JSON
  static Future<String?> getCurrentUserId() async {
    try {
      final userJson = await getUser();
      if (userJson == null) return null;
      final Map<String, dynamic> raw = jsonDecode(userJson);

      // Handle potential nesting (e.g., { "user": {...} } or { "data": {...} })
      final user = raw['user'] ?? raw['data'] ?? raw;

      // Check all common ID fields
      return user['id']?.toString() ??
          user['_id']?.toString() ??
          user['userId']?.toString() ??
          user['user_id']?.toString();
    } catch (_) {
      return null;
    }
  }

  // 📝 SUBMITTED APPLICATIONS (PERSISTENCE)
  static Future<void> saveSubmittedApplication(String applicationId) async {
    final userId = await getCurrentUserId() ?? 'guest';
    final List<String> currentList = await getSubmittedApplications();
    if (!currentList.contains(applicationId)) {
      currentList.add(applicationId);
      await _storage.write(
        key: 'submitted_apps_$userId',
        value: jsonEncode(currentList),
      );
    }
  }

  static Future<List<String>> getSubmittedApplications() async {
    final userId = await getCurrentUserId() ?? 'guest';
    final String? jsonString = await _storage.read(key: 'submitted_apps_$userId');
    if (jsonString == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveSubmittedJobId(String jobId) async {
    final userId = await getCurrentUserId() ?? 'guest';
    final List<String> currentList = await getSubmittedJobIds();
    if (!currentList.contains(jobId)) {
      currentList.add(jobId);
      await _storage.write(
        key: 'submitted_jobs_$userId',
        value: jsonEncode(currentList),
      );
    }
  }

  static Future<List<String>> getSubmittedJobIds() async {
    final userId = await getCurrentUserId() ?? 'guest';
    final String? jsonString = await _storage.read(key: 'submitted_jobs_$userId');
    if (jsonString == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  /// 🕵️ Helper to extract name from stored user JSON
  static Future<String?> getUserName() async {
    try {
      final userJson = await getUser();
      if (userJson == null) return null;
      final Map<String, dynamic> raw = jsonDecode(userJson);

      // Handle potential nesting
      final user = raw['user'] ?? raw['data'] ?? raw;

      // Check all common name fields
      return user['name']?.toString() ??
          user['username']?.toString() ??
          user['display_name']?.toString() ??
          user['displayName']?.toString();
    } catch (_) {
      return null;
    }
  }
}
