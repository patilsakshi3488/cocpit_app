import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cocpit_app/config/api_config.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart' as http_parser;

import 'auth_service.dart';
import 'secure_storage.dart';

class ApiClient {
  // ===================== GET =====================
  static Future<http.Response> get(String path) async {
    return _authorizedRequest(
      (headers) =>
          http.get(Uri.parse("${ApiConfig.baseUrl}$path"), headers: headers),
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

  // ===================== PATCH =====================
  static Future<http.Response> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _authorizedRequest(
      (headers) => http.patch(
        Uri.parse("${ApiConfig.baseUrl}$path"),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  // ===================== DELETE =====================
  static Future<http.Response> delete(String path) async {
    return _authorizedRequest(
      (headers) =>
          http.delete(Uri.parse("${ApiConfig.baseUrl}$path"), headers: headers),
    );
  }

  // ===================== MULTIPART =====================
  static Future<http.Response> multipart(
    String path, {
    required String fileField,
    File? file,
    List<File>? files,
    Map<String, String>? fields,
  }) async {
    Future<http.Response> makeRequest(String currentToken) async {
      final request = http.MultipartRequest(
        "POST",
        Uri.parse("${ApiConfig.baseUrl}$path"),
      );

      if (currentToken.isNotEmpty) {
        request.headers["Authorization"] = "Bearer $currentToken";
      }

      if (fields != null) request.fields.addAll(fields);

      if (file != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            fileField,
            file.path,
            contentType: http_parser.MediaType.parse(
              lookupMimeType(file.path) ?? 'image/jpeg',
            ),
          ),
        );
      }
      if (files != null) {
        for (var f in files) {
          request.files.add(
            await http.MultipartFile.fromPath(
              fileField,
              f.path,
              contentType: http_parser.MediaType.parse(
                lookupMimeType(f.path) ?? 'image/jpeg',
              ),
            ),
          );
        }
      }

      final streamed = await request.send().timeout(
        const Duration(seconds: 10),
      );
      return http.Response.fromStream(streamed);
    }

    String? token = await AppSecureStorage.getAccessToken();
    http.Response response = await makeRequest(token ?? "");

    if (response.statusCode == 401) {
      final newToken = await AuthService().refreshAccessToken();
      if (newToken != null) {
        response = await makeRequest(newToken);
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

    print("Making request to: ${ApiConfig.baseUrl}"); // Debug URL
    try {
      // ⏱️ Add 10s timeout (Chat needs faster feedback)
      http.Response response = await request(
        headers(),
      ).timeout(const Duration(seconds: 10));

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      // 🔁 Retry with fresh token
      if (response.statusCode == 401) {
        print("401 detected, refreshing token...");
        final newToken = await AuthService().refreshAccessToken();
        if (newToken != null) {
          token = newToken;
          response = await request(
            headers(),
          ).timeout(const Duration(seconds: 10));
        }
      }

      return response;
    } catch (e) {
      print("ApiClient Error: $e");
      rethrow;
    }
  }
}
