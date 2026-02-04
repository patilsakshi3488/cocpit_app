import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'cloudinary_service.dart';

class SocialService {
  /// 📨 Get All Conversations
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final response = await ApiClient.get(
        "/conversations",
      ); // Based on backend
      debugPrint(
        "Conversations Response: ${response.statusCode} | ${response.body}",
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint("❌ Error fetching conversations: $e");
    }
    return [];
  }

  /// 💬 Get Messages for a Conversation
  Future<List<Map<String, dynamic>>> getMessages(
    String conversationId, {
    String? before,
    int limit = 20,
  }) async {
    try {
      String path = "/conversations/$conversationId/messages?limit=$limit";
      if (before != null) {
        path += "&before=$before";
      }

      final response = await ApiClient.get(path);
      debugPrint("Messages Response: ${response.statusCode}");
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint("❌ Error fetching messages: $e");
    }
    return [];
  }

  /// 📤 Send a Message
  /// Returns the created message object or null on failure
  Future<Map<String, dynamic>?> sendMessage({
    required String targetUserId,
    String? content,
    String? sharedPostId,
    Map<String, dynamic>? sharedPostData,
    String? mediaUrl,
    String? mediaType,
  }) async {
    try {
      final Map<String, dynamic> body = {"targetUserId": targetUserId};
      if (content != null) body["text_content"] = content;
      if (sharedPostId != null) body["shared_post_id"] = sharedPostId;
      if (sharedPostData != null) body["shared_post_data"] = sharedPostData;
      if (mediaUrl != null) body["media_url"] = mediaUrl;
      if (mediaType != null) body["media_type"] = mediaType;

      final response = await ApiClient.post("/messages", body: body);

      debugPrint("SendMsg Response: ${response.statusCode} | ${response.body}");

      if (response.statusCode == 201) {
        final bodyJson = jsonDecode(response.body);
        return bodyJson['data']; // The message object is in 'data'
      }
    } catch (e) {
      debugPrint("❌ Error sending message: $e");
    }
    return null;
  }

  /// 👥 Get My Connections (Following) for sharing
  Future<List<Map<String, dynamic>>> getMyConnections() async {
    try {
      final response = await ApiClient.get("/connections/my");
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint("❌ Error fetching connections: $e");
    }
    return [];
  }

  /// 👀 Mark Conversation as Read
  Future<bool> markAsRead(String conversationId) async {
    try {
      final response = await ApiClient.patch(
        "/conversations/$conversationId/read",
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ Error marking as read: $e");
      return false;
    }
  }

  /// 🛎️ Get Notifications
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final response = await ApiClient.get("/notifications");
      debugPrint("Notifications Response: ${response.statusCode}");
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint("❌ Error fetching notifications: $e");
    }
    return [];
  }

  /// ✅ Mark Notification as Read
  Future<bool> markNotificationRead(String notificationId) async {
    try {
      final response = await ApiClient.patch(
        "/notifications/$notificationId/read",
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ Error marking notification read: $e");
      return false;
    }
  }

  /// 🖼️ Send a Media Message
  Future<Map<String, dynamic>?> sendMediaMessage({
    required String targetUserId,
    required File file,
    required String mediaType,
  }) async {
    try {
      // 1. Upload to Cloudinary first ( matches PostService pattern )
      debugPrint("☁️ Uploading media to Cloudinary...");
      final cloudinaryRes = await CloudinaryService.uploadFile(
        file,
        isVideo: mediaType == 'video',
      );
      final String mediaUrl = cloudinaryRes['url'];

      // 2. Send JSON to backend ( fixes the 500 error where req.body was missing )
      return await sendMessage(
        targetUserId: targetUserId,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
      );
    } catch (e) {
      debugPrint("❌ Error sending media message: $e");
    }
    return null;
  }
}
