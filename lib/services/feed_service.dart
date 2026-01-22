import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

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
  // ❤️ LIKES
  // =========================
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
}
