import 'dart:convert';
import 'package:flutter/foundation.dart';
// import '../config/api_config.dart';
import 'api_client.dart';

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
  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    try {
      final response = await ApiClient.get(
        "/conversations/$conversationId/messages",
      );
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
    required String content,
  }) async {
    try {
      final response = await ApiClient.post(
        "/messages",
        body: {"targetUserId": targetUserId, "text_content": content},
      );

      debugPrint("SendMsg Response: ${response.statusCode} | ${response.body}");

      if (response.statusCode == 201) {
        final body = jsonDecode(response.body);
        return body['data']; // The message object is in 'data'
      }
    } catch (e) {
      debugPrint("❌ Error sending message: $e");
    }
    return null;
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
}
