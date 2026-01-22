import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cocpit_app/config/api_config.dart';
import 'secure_storage.dart';
import 'auth_service.dart';

class ApiClient {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, String>> _headers() async {
    final token = await AppSecureStorage.getAccessToken();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  static Future<http.Response> _send(
      Future<http.Response> Function(Map<String, String> headers) request,
      ) async {
    var headers = await _headers();
    http.Response response = await request(headers);

    // 🔁 TOKEN EXPIRED → REFRESH → RETRY
    if (response.statusCode == 401) {
      final newToken = await AuthService().refreshAccessToken();
      if (newToken != null) {
        headers["Authorization"] = "Bearer $newToken";
        response = await request(headers);
      }
    }

    return response;
  }

  static Future<http.Response> get(String path) {
    return _send(
          (headers) => http.get(Uri.parse("$baseUrl$path"), headers: headers),
    );
  }

  static Future<http.Response> post(
      String path, {
        Map<String, dynamic>? body,
      }) {
    return _send(
          (headers) => http.post(
        Uri.parse("$baseUrl$path"),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  static Future<http.Response> put(
      String path, {
        Map<String, dynamic>? body,
      }) {
    return _send(
          (headers) => http.put(
        Uri.parse("$baseUrl$path"),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
  }

  static Future<http.Response> delete(String path) {
    return _send(
          (headers) => http.delete(Uri.parse("$baseUrl$path"), headers: headers),
    );
  }

  static Future<http.Response> multipart(
      String path, {
        required String fileField,
        required File file,
        Map<String, String>? fields,
      }) async {
    final token = await AppSecureStorage.getAccessToken();
    final request =
    http.MultipartRequest("POST", Uri.parse("$baseUrl$path"));

    if (token != null) {
      request.headers["Authorization"] = "Bearer $token";
    }

    if (fields != null) request.fields.addAll(fields);
    request.files.add(await http.MultipartFile.fromPath(fileField, file.path));

    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }
}
