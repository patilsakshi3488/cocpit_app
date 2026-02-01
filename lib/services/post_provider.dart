import 'package:flutter/material.dart';
import 'feed_service.dart';

class PostProvider extends ChangeNotifier {
  final Map<String, Map<String, dynamic>> _posts = {};

  /// Updates or adds a post to the provider.
  /// If the post already exists, it merges the new data with the old.
  void updatePost(Map<String, dynamic> post) {
    // Get ID safely
    final id = post["post_id"] ?? post["id"] ?? post["_id"];
    if (id == null) return;

    final postId = id.toString();

    if (_posts.containsKey(postId)) {

      final current = _posts[postId]!;
      _posts[postId] = {...current, ...post};
    } else {
      _posts[postId] = post;
    }

    notifyListeners();
  }

  /// Get a post by ID.
  Map<String, dynamic>? getPost(String postId) {
    return _posts[postId];
  }

  /// Toggles like status for a post.
  Future<void> toggleLike(String postId) async {
    if (!_posts.containsKey(postId)) return;

    final post = _posts[postId]!;
    final bool isLiked = post["is_liked"] == true;

    // Helper to handle mixed types safely
    int getSafeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value; // If it's already an int, return it
      return int.tryParse(value.toString()) ?? 0; // Otherwise, convert to string then parse
    }

    final int likeCount = getSafeInt(post["like_count"] ?? post["likes"]);

    // Optimistic update
    final updatedPost = Map<String, dynamic>.from(post);
    updatedPost["is_liked"] = !isLiked;
    updatedPost["like_count"] = isLiked
        ? (likeCount - 1).clamp(0, 999999).toInt()
        : (likeCount + 1);

    _posts[postId] = updatedPost;
    notifyListeners();

    try {
      await FeedApi.toggleLike(postId);
    } catch (e) {
      _posts[postId] = post;
      notifyListeners();
      rethrow;
    }
  }

  bool isPostLiked(String postId) {
    final post = _posts[postId];
    if (post == null) return false;
    return post["is_liked"] == true;
  }

  int getLikeCount(String postId) {
    final post = _posts[postId];
    if (post == null) return 0;

    var val = post["like_count"] ?? post["likes"];

    // Direct type check is the most efficient way to fix this
    if (val is int) return val;
    return int.tryParse(val.toString()) ?? 0;
  }




}
