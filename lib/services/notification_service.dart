import 'dart:async';
import 'package:flutter/foundation.dart';
import 'socket_service.dart';
import 'social_service.dart';
import 'chat_service.dart';
import 'package:flutter/material.dart';
import '../views/feed/post_detail_screen.dart';
import '../views/feed/chat_screen.dart';
import '../views/profile/public_profile_screen.dart';
import 'feed_service.dart';
import '../main.dart'; // for navigatorKey

enum NotificationCategory { chat, post, system }

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal() {
    _listenToSocket();
  }

  final SocketService _socketService = SocketService();
  final SocialService _socialService = SocialService();

  // State
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;

  // Deduplication cache for message IDs (keeps last 50 IDs to avoid duplicate toasts)
  final Set<String> _processedMessageIds = {};

  // Stream Controllers
  final _notificationsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final _unreadCountController = StreamController<int>.broadcast();
  final _newNotificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Public Streams
  Stream<List<Map<String, dynamic>>> get notificationsStream =>
      _notificationsController.stream;
  Stream<int> get unreadCountStream => _unreadCountController.stream;
  Stream<Map<String, dynamic>> get onNewNotification =>
      _newNotificationController.stream;

  // Public Accessors
  int get unreadCount => _unreadCount;
  List<Map<String, dynamic>> get currentNotifications =>
      List.from(_notifications);

  /// 🔄 Initialize: Fetch from API
  Future<void> loadNotifications() async {
    try {
      final List<Map<String, dynamic>>? data = await _socialService
          .getNotifications();

      if (data == null) return;

      // FILTER: Chat notifications should NOT stay inside notification list
      _notifications = data.where((n) {
        final type = n['type']?.toString().toLowerCase() ?? '';
        return type != 'message' && type != 'chat';
      }).toList();

      // Calculate unread count
      _countUnread();

      // Emit updates
      _notificationsController.add(List.from(_notifications));
      _unreadCountController.add(_unreadCount);
    } catch (e) {
      debugPrint("❌ Error loading notifications: $e");
    }
  }

  /// 👂 Listen to Socket Events
  void _listenToSocket() {
    // 1. Listen for generic notifications (Likes, Comments, Shares, etc.)
    _socketService.onNotification.listen(
      (data) => _handleIncomingNotification(data),
    );

    // 2. Also listen for specific new messages to ensure suppression works
    // regardless of which event reaches us first.
    _socketService.onNewMessage.listen((data) {
      // Convert newMessage format to notification-like format for processing
      final notifData = Map<String, dynamic>.from(data);
      if (notifData['type'] == null) notifData['type'] = 'message';
      _handleIncomingNotification(notifData);
    });
  }

  NotificationCategory _getCategory(String type) {
    type = type.toLowerCase();
    if (type == 'message' ||
        type == 'chat' ||
        type == 'new_message' ||
        type == 'chat_message') {
      return NotificationCategory.chat;
    }
    if (type == 'like' ||
        type == 'comment' ||
        type == 'share' ||
        type == 'follow') {
      return NotificationCategory.post;
    }
    return NotificationCategory.system;
  }

  void _handleIncomingNotification(Map<String, dynamic> data) {
    try {
      final String type = data['type']?.toString().toLowerCase() ?? 'system';
      final category = _getCategory(type);

      // A. Suppression & Deduplication
      if (category == NotificationCategory.chat) {
        if (_shouldSuppressChat(data)) return;
      }

      if (_isDuplicate(data)) return;

      // B. Process based on Category
      data['created_at'] ??= DateTime.now().toIso8601String();

      switch (category) {
        case NotificationCategory.chat:
          // Chat is transient: don't save to list
          break;
        case NotificationCategory.post:
        case NotificationCategory.system:
          _persistNotification(data);
          break;
      }

      // C. Alert for live Toast
      _newNotificationController.add(data);
    } catch (e) {
      debugPrint("❌ Error processing notification: $e");
    }
  }

  bool _shouldSuppressChat(Map<String, dynamic> data) {
    final notifConvId = (data['conversation_id'] ?? data['conversationId'])
        ?.toString();
    final activeConvId = ChatService().activeConversationId;

    if (notifConvId != null &&
        activeConvId != null &&
        notifConvId.trim().toLowerCase() == activeConvId.trim().toLowerCase()) {
      debugPrint("🔕 Suppressing notification for active chat");
      return true;
    }
    return false;
  }

  bool _isDuplicate(Map<String, dynamic> data) {
    final String? msgId =
        (data['message_id'] ?? data['id'] ?? data['notification_id'])
            ?.toString();
    if (msgId != null) {
      if (_processedMessageIds.contains(msgId)) {
        debugPrint("♻️ Duplicate notification ignored: $msgId");
        return true;
      }
      _processedMessageIds.add(msgId);
      if (_processedMessageIds.length > 50)
        _processedMessageIds.remove(_processedMessageIds.first);
    }
    return false;
  }

  void _persistNotification(Map<String, dynamic> data) {
    _notifications.insert(0, data);
    _countUnread();
    _unreadCountController.add(_unreadCount);
    _notificationsController.add(List.from(_notifications));
  }

  /// ✅ Mark as Read
  Future<void> markAsRead(String notificationId) async {
    // Optimistic Update
    final index = _notifications.indexWhere(
      (n) => n['notification_id'] == notificationId,
    );
    if (index != -1 && _notifications[index]['is_read'] != true) {
      _notifications[index]['is_read'] = true;
      _countUnread(); // Recalculate unread count
      _unreadCountController.add(_unreadCount); // Emit new unread count
      _notificationsController.add(
        List.from(_notifications),
      ); // Emit updated notifications list

      try {
        await _socialService.markNotificationRead(notificationId);
      } catch (e) {
        debugPrint("Error marking notification read: $e");
      }
    }
  }

  /// ✅ Mark All as Read
  Future<void> markAllAsRead() async {
    // Optimistic Update
    bool changed = false;
    for (var n in _notifications) {
      if (n['is_read'] != true) {
        n['is_read'] = true;
        changed = true;
        // Fire and forget individual updates (since no batch API)
        try {
          _socialService.markNotificationRead(n['notification_id']);
        } catch (e) {
          debugPrint("Error marking notification read: $e");
        }
      }
    }

    if (changed) {
      _countUnread(); // Recalculate unread count
      _unreadCountController.add(_unreadCount); // Emit new unread count
      _notificationsController.add(
        List.from(_notifications),
      ); // Emit updated notifications list
    }
  }

  /// 🗑 Remove a notification locally
  void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n['notification_id'] == notificationId);
    _countUnread();
    _unreadCountController.add(_unreadCount);
    _notificationsController.add(List.from(_notifications));
  }

  /// 🧹 Clear all notifications for a specific conversation
  void clearNotificationsForConversation(String conversationId) {
    final String targetId = conversationId.trim().toLowerCase();
    _notifications.removeWhere((n) {
      final String? notifConvId = (n['conversation_id'] ?? n['conversationId'])
          ?.toString()
          .trim()
          .toLowerCase();
      return notifConvId == targetId;
    });
    _countUnread();
    _unreadCountController.add(_unreadCount);
    _notificationsController.add(List.from(_notifications));
  }

  /// 🚀 Centralized Navigation Logic
  static Future<void> navigateToNotificationTarget(
    BuildContext context,
    Map<String, dynamic> n,
  ) async {
    final String type = n['type']?.toString().toLowerCase() ?? '';
    final String? actorId =
        (n['actor_id'] ??
                n['sender_id'] ??
                n['user_id'] ??
                n['actor']?['_id'] ??
                n['actor']?['id'])
            ?.toString();
    final actorData = n['actor'] ?? n['sender'] ?? {};
    final String actorName =
        (actorData['full_name'] ??
                actorData['name'] ??
                n['actor_name'] ??
                n['sender_name'])
            ?.toString() ??
        'User';
    final String? actorAvatar =
        (actorData['avatar_url'] ??
                actorData['avatar'] ??
                n['actor_avatar'] ??
                n['sender_avatar'])
            ?.toString();

    final String? referenceId =
        (n['reference_id'] ??
                n['post_id'] ??
                n['target_id'] ??
                n['referenceId'])
            ?.toString();

    // Mark as read in backend if ID exists
    final String? notifId = n['notification_id']?.toString();
    if (notifId != null) {
      NotificationService().markAsRead(notifId);
    }
    try {
      final category = NotificationService()._getCategory(type);

      // Handle Follow uniquely first
      if (type == 'follow') {
        if (actorId != null) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => PublicProfileScreen(userId: actorId),
            ),
          );
        } else {
          debugPrint("⚠️ Follow notification invalid: missing actorId");
        }
        return; // STOP here, do not fall through to post fetching
      }

      if (category == NotificationCategory.post) {
        if (referenceId != null) {
          // Like, Comment, Share -> View Post
          // Show dialog using navigatorKey context if possible, or just skip dialog
          // Better to just fetch silently or show a global loader if needed.
          // For now, let's just await.

          final post = await FeedApi.fetchSinglePost(referenceId);

          if (post != null) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
            );
          }
        }
      } else if (category == NotificationCategory.chat) {
        String? convId =
            (n['conversation_id'] ??
                    n['conversationId'] ??
                    n['chat_id'] ??
                    n['message']?['conversation_id'])
                ?.toString();

        // Robust fallback for nested conversation ID
        if (convId == null && n['message'] is Map) {
          convId =
              (n['message']['conversation_id'] ??
                      n['message']['conversationId'])
                  ?.toString();
        }
        // If it's a direct message object from socket, pull IDs from it
        final effectiveActorId =
            actorId ??
            (n['message']?['sender_id'] ?? n['message']?['sender']?['id'])
                ?.toString();

        if (convId != null) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => PersonalChatScreen(
                conversationId: convId!,
                otherUser: {
                  'id': effectiveActorId ?? '',
                  'name': actorName,
                  'avatar': actorAvatar,
                  'headline': '',
                },
              ),
            ),
          );
        } else {
          debugPrint(
            "❌ Navigation Failed: Custom Conversation ID missing in payload: $n",
          );
        }
      }
    } catch (e) {
      debugPrint("❌ Navigation Error: $e");
    }
  }

  /// 🧮 Helper: Count Unread
  void _countUnread() {
    _unreadCount = _notifications.where((n) => n['is_read'] != true).length;
  }
}
