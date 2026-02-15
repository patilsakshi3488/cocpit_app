import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class GroupChatService {
  static final GroupChatService _instance = GroupChatService._internal();
  factory GroupChatService() => _instance;
  GroupChatService._internal();

  /// ℹ️ Get Group Details
  Future<Map<String, dynamic>?> getGroupDetails(String groupId) async {
    try {
      final response = await ApiClient.get("/groups/$groupId");
      if (response.statusCode == 200) {
        final bodyJson = jsonDecode(response.body);
        return bodyJson['data'] ?? bodyJson;
      }
    } catch (e) {
      debugPrint("❌ Error fetching group details: $e");
    }
    return null;
  }

  /// ➕ Create Group
  Future<Map<String, dynamic>?> createGroup(
    String name,
    List<String> members, {
    String? description,
  }) async {
    try {
      final response = await ApiClient.post(
        "/groups",
        body: {
          "name": name,
          "members": members,
          if (description != null) "description": description,
        },
      );
      if (response.statusCode == 201) {
        final bodyJson = jsonDecode(response.body);
        return bodyJson['data'] ?? bodyJson;
      }
    } catch (e) {
      debugPrint("❌ Error creating group: $e");
    }
    return null;
  }

  /// 📤 Send Group Message
  Future<Map<String, dynamic>?> sendGroupMessage(
    String groupId,
    String content,
  ) async {
    try {
      final response = await ApiClient.post(
        "/groups/$groupId/messages",
        body: {"text_content": content},
      );
      debugPrint("SendGroupMsg Response: ${response.statusCode}");
      if (response.statusCode == 201) {
        final bodyJson = jsonDecode(response.body);
        return bodyJson['data'] ?? bodyJson;
      }
    } catch (e) {
      debugPrint("❌ Error sending group message: $e");
    }
    return null;
  }

  /// 🖼️ Send Group Media Message
  Future<Map<String, dynamic>?> sendGroupMediaMessage({
    required String groupId,
    required File file,
    required String mediaType,
  }) async {
    try {
      final response = await ApiClient.multipart(
        "/groups/$groupId/messages",
        fileField: "media",
        file: file,
        fields: {"media_type": mediaType},
      );

      debugPrint("SendGroupMedia Response: ${response.statusCode}");
      if (response.statusCode == 201) {
        final bodyJson = jsonDecode(response.body);
        return bodyJson['data'] ?? bodyJson;
      }
    } catch (e) {
      debugPrint("❌ Error sending group media message: $e");
    }
    return null;
  }

  /// ✉️ Invite Member
  Future<bool> inviteMember(String groupId, String userId) async {
    try {
      final response = await ApiClient.post(
        "/groups/$groupId/invite",
        body: {"userId": userId},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("❌ Error inviting member: $e");
      return false;
    }
  }

  /// ➖ Remove Member
  Future<bool> removeMember(String groupId, String userId) async {
    try {
      final response = await ApiClient.delete(
        "/groups/$groupId/members/$userId",
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ Error removing member: $e");
      return false;
    }
  }

  /// 🚪 Leave Group
  Future<bool> leaveGroup(String groupId) async {
    try {
      final response = await ApiClient.post("/groups/$groupId/leave");
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ Error leaving group: $e");
      return false;
    }
  }

  /// 🗑️ Delete Group
  Future<bool> deleteGroup(String groupId) async {
    try {
      final response = await ApiClient.delete("/groups/$groupId");
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint("❌ Error deleting group: $e");
      return false;
    }
  }

  /// 📨 Get Pending Invitations
  Future<List<Map<String, dynamic>>> getPendingInvitations() async {
    try {
      final response = await ApiClient.get("/groups/invitations");
      if (response.statusCode == 200) {
        final bodyJson = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(bodyJson['data'] ?? bodyJson);
      }
    } catch (e) {
      debugPrint("❌ Error fetching invitations: $e");
    }
    return [];
  }

  /// ✅ Accept Invitation
  Future<bool> acceptInvitation(String groupId) async {
    try {
      final response = await ApiClient.post("/groups/$groupId/accept");
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("❌ Error accepting invitation: $e");
      return false;
    }
  }

  /// ❌ Reject Invitation
  Future<bool> rejectInvitation(String groupId) async {
    try {
      final response = await ApiClient.post("/groups/$groupId/reject");
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ Error rejecting invitation: $e");
      return false;
    }
  }

  /// 🖼️ Update Group Avatar
  Future<bool> updateGroupAvatar(String groupId, File imageFile) async {
    try {
      final response = await ApiClient.multipart(
        "/groups/$groupId/avatar",
        fileField: "group_avatar", // Updated key as per user request
        file: imageFile,
        method: "PATCH", // Using PATCH as it's an update
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ Error updating group avatar: $e");
      return false;
    }
  }
}
