import 'dart:convert';
import 'package:cocpit_app/config/api_config.dart';
import 'package:cocpit_app/models/story_model.dart';
import 'package:cocpit_app/services/api_client.dart';

class StoryService {
  static Future<List<StoryGroup>> getGroupedStories() async {
    final response = await ApiClient.get(ApiConfig.storiesGrouped);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => StoryGroup.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load stories");
    }
  }

  static Future<void> createStory({
    String? title, // Nullable now preferred
    String? description,
    required String mediaUrl,
    Map<String, dynamic>? storyMetadata,
  }) async {
    final body = {
      "title": title,
      "description": description,
      "media_url": mediaUrl,
      if (storyMetadata != null) "story_metadata": storyMetadata,
    };

    final response = await ApiClient.post(ApiConfig.story, body: body);

    if (response.statusCode != 201) {
      throw Exception("Failed to create story");
    }
  }

  static Future<void> deleteStory(String storyId) async {
    final response = await ApiClient.delete("${ApiConfig.stories}/$storyId");

    if (response.statusCode != 200) {
      throw Exception("Failed to delete story");
    }
  }

  static Future<void> viewStory(String storyId) async {
    final response = await ApiClient.post("${ApiConfig.stories}/$storyId/view");

    // 200 OK
    if (response.statusCode != 200) {
      // It might return 404 or other, but usually we just ignore errors for view tracking or log them
      print("Failed to record view for story $storyId: ${response.statusCode}");
    }
  }

  static Future<bool> reactToStory(String storyId, String reaction) async {
    final response = await ApiClient.post(
      "${ApiConfig.stories}/$storyId/react",
      body: {"reaction": reaction},
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      // Backend returns { is_liked: boolean, ... }
      return body['is_liked'] ?? false;
    } else {
      throw Exception("Failed to react to story");
    }
  }

  static Future<Map<String, dynamic>> getStoryDetails(String storyId) async {
    final response = await ApiClient.get("${ApiConfig.stories}/$storyId");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to get story details");
    }
  }

  // ======================
  // 💬 COMMENTS
  // ======================

  static Future<List<StoryComment>> fetchComments(String storyId) async {
    final response = await ApiClient.get(
      "${ApiConfig.stories}/$storyId/comments",
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.map((e) => StoryComment.fromJson(e)).toList();
      } else if (decoded is Map && decoded['comments'] != null) {
        return (decoded['comments'] as List)
            .map((e) => StoryComment.fromJson(e))
            .toList();
      }
      return [];
    } else {
      throw Exception("Failed to load comments");
    }
  }

  static Future<StoryComment> postComment(
    String storyId,
    String content,
  ) async {
    final response = await ApiClient.post(
      "${ApiConfig.stories}/$storyId/comments",
      body: {"content": content},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      // Return parsed comment if possible, else we might fetch again
      if (decoded is Map<String, dynamic>) {
        // If backend returns the comment directly
        if (decoded.containsKey('id')) {
          return StoryComment.fromJson(decoded);
        }
        // If nested in 'comment' key
        if (decoded.containsKey('comment')) {
          return StoryComment.fromJson(decoded['comment']);
        }
      }
      // Fallback mock if backend returns minimal success
      return StoryComment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        storyId: storyId,
        userId: "current",
        content: content,
        createdAt: DateTime.now(),
        likeCount: 0,
        isLiked: false,
      );
    } else {
      throw Exception("Failed to post comment");
    }
  }

  static Future<bool> likeComment(String commentId) async {
    // Assuming pattern: /stories/comments/{id}/like
    final response = await ApiClient.post(
      "${ApiConfig.stories}/comments/$commentId/like",
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['is_liked'] ?? false;
    } else {
      // If 404, maybe standard path differs, but sticking to plan
      throw Exception("Failed to like comment");
    }
  }

  static Future<void> deleteComment(String commentId) async {
    final response = await ApiClient.delete(
      "${ApiConfig.stories}/comments/$commentId",
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete comment");
    }
  }
}
