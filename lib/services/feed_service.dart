import 'dart:convert';
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
      // Supports both { comments: [] } and direct []
      final List raw = (decoded is Map && decoded.containsKey("comments"))
          ? decoded["comments"]
          : (decoded is List ? decoded : []);

      return raw.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Failed to fetch comments: ${response.statusCode}");
    }
  }

  static Future<void> addComment(String postId, String content) async {
    final response = await ApiClient.post(
      "/post/$postId/comment",
      body: {"content": content},
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Failed to add comment: ${response.statusCode}");
    }
  }

  static Future<void> updateComment(String commentId, String content) async {
    final response = await ApiClient.put(
      "/comment/$commentId",
      body: {"content": content},
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update comment: ${response.statusCode}");
    }
  }

  static Future<void> deleteComment(String commentId) async {
    final response = await ApiClient.delete("/comment/$commentId");

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
