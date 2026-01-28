import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // ======================
  // ENVIRONMENT SETTINGS
  // ======================

  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? "http://192.168.1.7:5000/api";

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
  // ONBOARDING ENDPOINTS
  // ======================
  static String get checkAccountName => "/onboarding/check-account-name";
  static String get completeOnboarding => "/onboarding/complete";

  // ======================
  // EVENT ENDPOINTS
  // ======================
  static String get events => "/events";

  // ======================
  // POST ENDPOINTS
  // ======================
  static String get posts =>
      "/post"; // Singular based on backend: router.post("/post", ...)
  static String get upload =>
      "/upload"; // Based on backend: router.post("/upload", ...)

  // ======================
  // STORY ENDPOINTS
  // ======================
  static String get storiesGrouped => "/stories/grouped";
  static String get story => "/story"; // For POST /story
  static String get stories => "/stories";
}
