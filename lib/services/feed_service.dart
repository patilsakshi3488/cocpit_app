import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

import '../config/api_config.dart';
import 'dart:io';

class FeedApi {
  // =========================
  // 🏠 FETCH FEED
  // =========================
  static Future<Map<String, dynamic>> fetchFeed({
    String? cursorCreatedAt,
    String? cursorPostId,
  }) async {
    String url = "/All/feeds";
    final params = <String>[];

    if (cursorCreatedAt != null) {
      params.add("cursorCreatedAt=${Uri.encodeComponent(cursorCreatedAt)}");
    }
    if (cursorPostId != null) {
      params.add("cursorPostId=${Uri.encodeComponent(cursorPostId)}");
    }

    if (params.isNotEmpty) {
      url += "?${params.join("&")}";
    }

    final response = await ApiClient.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch feed: ${response.statusCode}");
    }
  }

  // =========================
  // 👤 FETCH MY POSTS
  // =========================
  static Future<Map<String, dynamic>> fetchMyPosts({
    String? cursorCreatedAt,
    String? cursorPostId,
  }) async {
    String url = "/users/me/posts?limit=10";
    final params = <String>[];

    if (cursorCreatedAt != null) {
      params.add("cursorCreatedAt=${Uri.encodeComponent(cursorCreatedAt)}");
    }
    if (cursorPostId != null) {
      params.add("cursorPostId=${Uri.encodeComponent(cursorPostId)}");
    }

    if (params.isNotEmpty) {
      url += "&${params.join("&")}";
    }

    final response = await ApiClient.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch my posts: ${response.statusCode}");
    }
  }

  // =========================
  // 👤 FETCH ANY USER POSTS
  // =========================
  static Future<Map<String, dynamic>> fetchUserPosts({
    required String userId,
    String? cursorCreatedAt,
    String? cursorPostId,
  }) async {
    String url = "/users/$userId/posts?limit=10";
    final params = <String>[];

    if (cursorCreatedAt != null) {
      params.add("cursorCreatedAt=${Uri.encodeComponent(cursorCreatedAt)}");
    }
    if (cursorPostId != null) {
      params.add("cursorPostId=${Uri.encodeComponent(cursorPostId)}");
    }

    if (params.isNotEmpty) {
      url += "&${params.join("&")}";
    }

    final response = await ApiClient.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch user posts: ${response.statusCode}");
    }
  }

  static Future<Map<String, dynamic>> toggleLike(String postId) async {
    final response = await ApiClient.post("/post/$postId/like");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to toggle like: ${response.statusCode}");
    }
  }

  // =========================
  // 💬 COMMENTS
  // =========================
  static Future<List<Map<String, dynamic>>> fetchComments(String postId) async {
    final response = await ApiClient.get("/post/$postId/comments");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map && decoded["comments"] != null) {
        return List<Map<String, dynamic>>.from(decoded["comments"]);
      }

      if (decoded is Map && decoded["data"]?["comments"] != null) {
        return List<Map<String, dynamic>>.from(decoded["data"]["comments"]);
      }

      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }

      return [];
    } else {
      debugPrint("❌ Fetch comments failed: ${response.body}");
      throw Exception("Failed to load comments");
    }
  }

  static Future<void> addComment(String postId, String content) async {
    // Corrected Route: /post/:id/comments
    final response = await ApiClient.post(
      "/post/$postId/comments",
      body: {"content": content},
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Failed to add comment: ${response.statusCode}");
    }
  }

  static Future<void> updateComment(String commentId, String content) async {
    // Corrected Route: /post/comments/:comment_id
    final response = await ApiClient.put(
      "/post/comments/$commentId",
      body: {"content": content},
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update comment: ${response.statusCode}");
    }
  }

  static Future<void> deleteComment(String commentId) async {
    // Corrected Route: /post/comments/:comment_id
    final response = await ApiClient.delete("/post/comments/$commentId");

    if (response.statusCode != 200) {
      throw Exception("Failed to delete comment: ${response.statusCode}");
    }
  }

  // =========================
  // 📊 POLLS
  // =========================
  static Future<void> votePoll(String postId, String optionId) async {
    final response = await ApiClient.post(
      "/post/$postId/poll/vote",
      body: {"option_id": optionId},
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Failed to vote poll: ${response.statusCode}");
    }
  }

  static Future<void> removePollVote(String postId) async {
    final response = await ApiClient.delete("/post/$postId/poll/vote");

    if (response.statusCode != 200) {
      throw Exception("Failed to remove poll vote: ${response.statusCode}");
    }
  }

  static Future<Map<String, dynamic>?> fetchSinglePost(String postId) async {
    final response = await ApiClient.get("/post/$postId");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  // =========================
  // ☁️ UPLOAD MEDIA
  // =========================
  static Future<List<Map<String, dynamic>>> uploadMedia(
    List<File> files,
  ) async {
    // Backend expects field "files"
    final response = await ApiClient.multipart(
      ApiConfig.upload,
      fileField: "files",
      files: files,
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      // Backend returns { "urls": [ { "url": "...", "media_type": "..." } ] }
      if (decoded["urls"] != null) {
        return List<Map<String, dynamic>>.from(decoded["urls"]);
      }
      return [];
    } else {
      throw Exception("Failed to upload media: ${response.statusCode}");
    }
  }

  // =========================
  // ➕ CREATE POST
  // =========================
  static Future<void> createPost({
    required String content,
    List<String>? mediaUrls,
    String? postType, // 'image', 'video', 'text', 'poll', 'article'
    Map<String, dynamic>? pollData,
    String category = 'Professional',
    String visibility = 'public',
    String title = '',
    String? sharedPostId, // New parameter for reposts
  }) async {
    // Construct Payload
    final Map<String, dynamic> body = {
      "content": content,
      "category": category,
      "visibility": visibility,
      "title": title,
    };

    if (sharedPostId != null) {
      body["shared_post_id"] = sharedPostId;
    }

    if (mediaUrls != null && mediaUrls.isNotEmpty) {
      body["media_urls"] = mediaUrls;
    }

    // Determine Post Type
    if (postType != null) {
      body["post_type"] = postType;
    } else {
      // Fallback logic if null
      if (pollData != null) {
        body["post_type"] = "poll";
      } else if (mediaUrls != null && mediaUrls.isNotEmpty) {
        // Simplistic check, UI should pass correct type
        body["post_type"] = "image";
      } else {
        body["post_type"] = "text";
      }
    }

    if (pollData != null) {
      if (pollData["options"] != null) {
        body["poll_options"] = pollData["options"];
      }
      if (pollData["duration"] != null) {
        body["poll_duration"] = pollData["duration"];
      }
    }

    // Send JSON
    final response = await ApiClient.post(ApiConfig.posts, body: body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        "Failed to create post: ${response.statusCode} - ${response.body}",
      );
    }
  }

  // =========================
  // 📝 MANAGE POST
  // =========================
  static Future<void> deletePost(String postId) async {
    final response = await ApiClient.delete("/post/$postId");

    if (response.statusCode != 200) {
      throw Exception("Failed to delete post: ${response.statusCode}");
    }
  }

  static Future<void> updatePost(
    String postId, {
    String? content,
    String? title,
    String? visibility,
  }) async {
    final body = <String, dynamic>{};
    if (content != null) body['content'] = content;
    if (title != null) body['title'] = title;
    if (visibility != null) body['visibility'] = visibility;

    final response = await ApiClient.put("/post/$postId", body: body);

    if (response.statusCode != 200) {
      throw Exception("Failed to update post: ${response.statusCode}");
    }
  }

  static Future<void> setPostVisibility(String postId, bool isPrivate) async {
    final visibility = isPrivate ? 'private' : 'public';
    await updatePost(postId, visibility: visibility);
  }
}
