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
      // Merge: only update keys that are present in the new map
      // But for simplicity and to ensure we have the latest, we can just overwrite
      // or selectively update.
      // However, we want to PRESERVE local state if the new map is stale,
      // but usually the new map is fresher (e.g. from API).
      // A safe bet is to merge.
      final current = _posts[postId]!;
      _posts[postId] = {...current, ...post};
    } else {
      _posts[postId] = post;
    }
    // We notify listeners only if we want general updates,
    // but PostCard will select specific posts, so this might trigger rebuilds
    // if we listened to the whole map.
    // Since we use selector on specific keys/values, general notifyListeners()
    // is needed for Selectors to re-evaluate.
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
    final int likeCount = post["like_count"] ?? post["likes"] ?? 0;

    // Optimistic update
    final updatedPost = Map<String, dynamic>.from(post);
    updatedPost["is_liked"] = !isLiked;
    updatedPost["like_count"] = isLiked ? (likeCount - 1) : (likeCount + 1);

    _posts[postId] = updatedPost;
    notifyListeners();

    try {
      await FeedApi.toggleLike(postId);
    } catch (e) {
      // Revert on failure
      _posts[postId] = post;
      notifyListeners();
      rethrow;
    }
  }

  /// Increment comment count.
  void incrementCommentCount(String postId) {
    if (!_posts.containsKey(postId)) return;

    final post = _posts[postId]!;
    final int commentCount = post["comment_count"] ?? post["comments_count"] ?? 0;

    final updatedPost = Map<String, dynamic>.from(post);
    updatedPost["comment_count"] = commentCount + 1;

    _posts[postId] = updatedPost;
    notifyListeners();
  }
}
