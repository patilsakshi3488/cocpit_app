import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cocpit_app/services/secure_storage.dart';

class LocalJobService {
  static const String _keyPosted = 'posted_jobs';
  static const String _keyApplied = 'applied_jobs';
  static const String _keySaved = 'saved_jobs';

  // Helper to get a user-specific key
  Future<String> _getUserKey(String baseKey) async {
    // We assume user info is stored in secure storage. 
    // If we can't find a user ID, we fallback to 'guest'.
    // Ideally, we parse the stored user JSON.
    String? userJson = await AppSecureStorage.getUser();
    String userId = "guest";
    if (userJson != null) {
      try {
        final Map<String, dynamic> user = jsonDecode(userJson);
        userId = user['_id'] ?? user['id'] ?? "guest";
      } catch (e) {
      }
    }
    return "${userId}_$baseKey";
  }

  // ================= POSTED JOBS =================

  Future<void> savePostedJobs(List<Map<String, dynamic>> jobs) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getUserKey(_keyPosted);
    final String data = jsonEncode(jobs);
    await prefs.setString(key, data);
  }

  Future<List<Map<String, dynamic>>> getPostedJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getUserKey(_keyPosted);
    final String? data = prefs.getString(key);
    if (data == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // ================= APPLIED JOBS =================

  Future<void> saveAppliedJobs(List<Map<String, dynamic>> jobs) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getUserKey(_keyApplied);
    final String data = jsonEncode(jobs);
    await prefs.setString(key, data);
  }

  Future<List<Map<String, dynamic>>> getAppliedJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getUserKey(_keyApplied);
    final String? data = prefs.getString(key);
    if (data == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // ================= SAVED JOBS =================

  Future<void> saveSavedJobs(List<Map<String, dynamic>> jobs) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getUserKey(_keySaved);
    final String data = jsonEncode(jobs);
    await prefs.setString(key, data);
  }

  Future<List<Map<String, dynamic>>> getSavedJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getUserKey(_keySaved);
    final String? data = prefs.getString(key);
    if (data == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }
}
