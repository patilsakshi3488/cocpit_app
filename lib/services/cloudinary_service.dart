import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as path;

class CloudinaryService {
  static final _cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME']!;
  static final _uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET']!;

  // Limits
  static const int _maxImageBytes = 5 * 1024 * 1024; // 5MB
  static const int _maxVideoBytes = 50 * 1024 * 1024; // 50MB
  static const List<String> _allowedImageExts = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  ];
  static const List<String> _allowedVideoExts = ['.mp4', '.mov'];

  /// 📤 Upload File with Validation
  static Future<String> uploadFile(File file, {bool isVideo = false}) async {
    // 1. Validation
    await _validateFile(file, isVideo);

    // 2. Upload
    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/$_cloudName/${isVideo ? 'video' : 'image'}/upload",
    );

    final request = http.MultipartRequest("POST", uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath("file", file.path));

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception(
        "Cloudinary upload failed: ${response.statusCode} - $resBody",
      );
    }

    final data = jsonDecode(resBody);
    return data['secure_url']; // Return base secure URL
  }

  /// 🔍 File Validation Logic
  static Future<void> _validateFile(File file, bool isVideo) async {
    if (!await file.exists()) throw Exception("File does not exist");

    final length = await file.length();
    final ext = path.extension(file.path).toLowerCase();

    if (isVideo) {
      if (length > _maxVideoBytes)
        throw Exception("Video size exceeds 50MB limit");
      if (!_allowedVideoExts.contains(ext))
        throw Exception("Invalid video format. Allowed: $_allowedVideoExts");
    } else {
      if (length > _maxImageBytes)
        throw Exception("Image size exceeds 5MB limit");
      if (!_allowedImageExts.contains(ext))
        throw Exception("Invalid image format. Allowed: $_allowedImageExts");
    }
  }

  /// 🖼️ Optimize Image URL (Responsive)
  /// Usage: optimizeImage(url, width: 1080) for Feed
  /// Usage: optimizeImage(url, width: 400) for Grid
  static String optimizeImage(String url, {int? width}) {
    if (!url.contains("cloudinary.com")) return url;

    // Inject transformations: f_auto,q_auto,w_{width}
    // Standard Cloudinary URL structure: .../upload/{transformations}/v1234/id

    final transformations = [
      "f_auto",
      "q_auto",
      if (width != null) "c_limit,w_$width",
    ].join(",");

    return _injectTransformation(url, transformations);
  }

  /// 🎥 Optimize Video Stream (HLS/DASH or mp4)
  /// Usage: getVideoStreamUrl(url) -> returns sp_auto (HLS/DASH)
  static String getVideoStreamUrl(String url) {
    if (!url.contains("cloudinary.com")) return url;

    // sp_auto generates HLS (.m3u8) or DASH (.mpd) suitable for streaming players
    // If using simple video_player with .mp4 expectation, use "f_mp4,q_auto" instead.
    // User requested "sp_auto", which is meant for adaptive streaming.

    // NOTE: 'sp_auto' often changes file extension handling implicitly.
    // Ideally, for simple Flutter apps, 'f_auto,q_auto' is safer as it keeps it as a single file
    // unless you have a player that explicitly supports adaptive (like chewie + video_player usually prefer mp4).
    // However, abiding by request:

    return _injectTransformation(url, "sp_auto");
  }

  /// 🛠️ Helper to inject string into URL
  static String _injectTransformation(String url, String transformation) {
    if (url.contains("/upload/")) {
      return url.replaceFirst("/upload/", "/upload/$transformation/");
    }
    return url;
  }
}
