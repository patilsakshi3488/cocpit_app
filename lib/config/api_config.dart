import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // ======================
  // ENVIRONMENT SETTINGS
  // ======================

  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? "http://192.168.1.6:5000/api";

  // ======================
  // AUTH ENDPOINTS (PATHS)
  // ======================
  // These are relative paths to be used with ApiClient

  static String get login => "/auth/login";
  static String get register => "/auth/register";
  static String get refresh => "/auth/refresh";
  static String get logout => "/auth/logout";
  static String get me => "/auth/me";
  static String get searchUsers => "/users/search";
  static String get getPublicProfile => "/users";

  // ======================
  // EVENT ENDPOINTS
  // ======================
  static String get events => "/events";

  // ======================
  // POST ENDPOINTS
  // ======================
  static String get posts => "/posts";
}
