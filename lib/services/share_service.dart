import 'package:flutter/material.dart';
import 'social_service.dart';

class ShareService {
  final SocialService _socialService = SocialService();

  /// Share a post to multiple users
  Future<bool> shareToUsers({
    required String postId,
    required List<String> userIds,
    String? message,
    Map<String, dynamic>? sharedPostData,
  }) async {
    bool allSuccess = true;
    for (final userId in userIds) {
      final result = await _socialService.sendMessage(
        targetUserId: userId,
        content: message,
        sharedPostId: postId,
        sharedPostData: sharedPostData,
      );
      if (result == null) allSuccess = false;
    }
    return allSuccess;
  }

  /// Get potential share targets (combined list of conversations and connections)
  Future<List<Map<String, dynamic>>> getShareTargets() async {
    try {
      // Fetch both for a comprehensive list
      final conversations = await _socialService.getConversations();
      final connections = await _socialService.getMyConnections();

      // Normalize and deduplicate
      final Map<String, Map<String, dynamic>> targets = {};

      for (final conv in conversations) {
        final id = conv['other_user_id']?.toString();
        if (id != null) {
          targets[id] = {
            'id': id,
            'name': conv['other_user_name'] ?? 'User',
            'avatar': conv['other_user_avatar'],
            'headline': conv['other_user_headline'] ?? '',
          };
        }
      }

      for (final conn in connections) {
        final id = conn['user_id']?.toString();
        if (id != null && !targets.containsKey(id)) {
          targets[id] = {
            'id': id,
            'name': conn['full_name'] ?? 'User',
            'avatar': conn['avatar_url'],
            'headline': conn['headline'] ?? '',
          };
        }
      }

      return targets.values.toList();
    } catch (e) {
      debugPrint("❌ Error fetching share targets: $e");
      return [];
    }
  }
}
