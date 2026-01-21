import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cocpit_app/config/api_config.dart';

import 'auth_service.dart';
import 'secure_storage.dart';

class ApiClient {

  // ===================== GET =====================
  static Future<http.Response> get(String path) async {
    return _authorizedRequest(
          (headers) => http.get(Uri.parse("${ApiConfig.baseUrl}$path"), headers: headers),
    );
  }

  // ===================== POST =====================
  static Future<http.Response> post(
      String path, {
        Map<String, dynamic>? body,
      }) async {
    return _authorizedRequest(
          (headers) => http.post(
        Uri.parse("${ApiConfig.baseUrl}$path"),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  // ===================== PUT =====================
  static Future<http.Response> put(
      String path, {
        Map<String, dynamic>? body,
      }) async {
    return _authorizedRequest(
          (headers) => http.put(
        Uri.parse("${ApiConfig.baseUrl}$path"),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  // ===================== DELETE =====================
  static Future<http.Response> delete(String path) async {
    return _authorizedRequest(
          (headers) => http.delete(Uri.parse("${ApiConfig.baseUrl}$path"), headers: headers),
    );
  }

  // ===================== MULTIPART =====================
  static Future<http.Response> multipart(
      String path, {
        required String fileField,
        required File file,
        Map<String, String>? fields,
      }) async {
    Future<http.Response> send(String token) async {
      final request =
      http.MultipartRequest("POST", Uri.parse("${ApiConfig.baseUrl}$path"));

      request.headers["Authorization"] = "Bearer $token";

      if (fields != null) request.fields.addAll(fields);

      request.files.add(
        await http.MultipartFile.fromPath(fileField, file.path),
      );

      final streamed = await request.send();
      return http.Response.fromStream(streamed);
    }

    final token = await AppSecureStorage.getAccessToken();
    if (token == null) throw Exception("No access token");

    http.Response response = await send(token);

    if (response.statusCode == 401) {
      final newToken = await AuthService().refreshAccessToken();
      if (newToken != null) {
        response = await send(newToken);
      }
    }

    return response;
  }

  // ===================== CORE AUTH HANDLER =====================
  static Future<http.Response> _authorizedRequest(
      Future<http.Response> Function(Map<String, String> headers) request,
      ) async {
    String? token = await AppSecureStorage.getAccessToken();

    Map<String, String> headers() => {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    http.Response response = await request(headers());

    // 🔁 Retry with fresh token
    if (response.statusCode == 401) {
      final newToken = await AuthService().refreshAccessToken();
      if (newToken != null) {
        token = newToken;
        response = await request(headers());
      }
    }

    return response;
  }
}
