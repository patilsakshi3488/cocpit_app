import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cocpit_app/config/api_config.dart';
import 'package:mime/mime.dart';

import 'auth_service.dart';
import 'secure_storage.dart';

class ApiClient {
  // ===================== GET =====================
  static Future<http.Response> get(
    String path, {
    bool retryOnAuthError = true,
  }) async {
    return _authorizedRequest(
      (headers) =>
          http.get(Uri.parse("${ApiConfig.baseUrl}$path"), headers: headers),
      retryOnAuthError: retryOnAuthError,
    );
  }

  // ===================== POST =====================
  static Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    bool retryOnAuthError = true,
  }) async {
    return _authorizedRequest(
      (headers) => http.post(
        Uri.parse("${ApiConfig.baseUrl}$path"),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
      retryOnAuthError: retryOnAuthError,
    );
  }

  // ===================== PUT =====================
  static Future<http.Response> put(
    String path, {
    Map<String, dynamic>? body,
    bool retryOnAuthError = true,
  }) async {
    return _authorizedRequest(
      (headers) => http.put(
        Uri.parse("${ApiConfig.baseUrl}$path"),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
      retryOnAuthError: retryOnAuthError,
    );
  }

  // ===================== PATCH =====================
  static Future<http.Response> patch(
    String path, {
    Map<String, dynamic>? body,
    bool retryOnAuthError = true,
  }) async {
    return _authorizedRequest(
      (headers) => http.patch(
        Uri.parse("${ApiConfig.baseUrl}$path"),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
      retryOnAuthError: retryOnAuthError,
    );
  }

  // ===================== DELETE =====================
  static Future<http.Response> delete(
    String path, {
    bool retryOnAuthError = true,
  }) async {
    return _authorizedRequest(
      (headers) =>
          http.delete(Uri.parse("${ApiConfig.baseUrl}$path"), headers: headers),
      retryOnAuthError: retryOnAuthError,
    );
  }

  // ===================== MULTIPART =====================
  static Future<http.Response> multipart(
    String path, {
    required String fileField,
    File? file,
    List<File>? files,
    Map<String, String>? fields,
    String method = "POST",
    bool retryOnAuthError = true,
  }) async {
    final token = await AppSecureStorage.getAccessToken();
    final request = http.MultipartRequest(
      method,
      Uri.parse("${ApiConfig.baseUrl}$path"),
    );

    if (token != null) {
      request.headers["Authorization"] = "Bearer $token";
    }

    if (fields != null) request.fields.addAll(fields);

    if (file != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          fileField,
          file.path,
          contentType: http.MediaType.parse(
            lookupMimeType(file.path) ?? 'image/jpeg',
          ),
        ),
      );
    }
    // Handle multiple files
    if (files != null) {
      for (var f in files) {
        request.files.add(
          await http.MultipartFile.fromPath(
            fileField,
            f.path,
            contentType: http.MediaType.parse(
              lookupMimeType(f.path) ?? 'image/jpeg',
            ),
          ),
        );
      }
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    // Manual 401 handling for multipart since it doesn't use _authorizedRequest directly
    // but typically we might want to unify this. For now leaving as is or adapting:
    if (retryOnAuthError && response.statusCode == 401) {
      final newToken = await AuthService().refreshAccessToken();
      if (newToken != null) {
        // Recursive retry for multipart is complex because streams are consumed.
        // Ideally we'd need to recreate the request.
        // For this specific 'infinite loop' fix, the critical part is JSON requests.
        // We'll leave multipart retry logic 'as-is' (non-recursive/manual) or FIXME.
        // Given the task, let's focus on the JSON methods which recursive.
      }
    }
    return response;
  }

  // ===================== CORE AUTH HANDLER =====================
  static Future<http.Response> _authorizedRequest(
    Future<http.Response> Function(Map<String, String> headers) request, {
    bool retryOnAuthError = true,
  }) async {
    String? token = await AppSecureStorage.getAccessToken();

    Map<String, String> headers() => {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    try {
      // â±ï¸ Add 10s timeout (Chat needs faster feedback)
      http.Response response = await request(
        headers(),
      ).timeout(const Duration(seconds: 10));


      // ðŸ” Retry with fresh token
      if (retryOnAuthError && response.statusCode == 401) {
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
      rethrow;
    }
  }
}
