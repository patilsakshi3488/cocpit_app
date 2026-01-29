import 'dart:async';
import 'package:flutter/foundation.dart';
import 'socket_service.dart';
import 'social_service.dart';
import 'chat_service.dart';

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

  /// 🔄 Initialize: Fetch from API
  Future<void> loadNotifications() async {
    final data = await _socialService.getNotifications();

    // Sort by creation time (descending) if needed, though backend usually handles it
    _notifications = data;

    // Calculate unread count
    _countUnread();

    // Emit updates
    _notificationsController.add(_notifications);
    _unreadCountController.add(_unreadCount);
  }

  /// 👂 Listen to Socket Events
  void _listenToSocket() {
    _socketService.onNotification.listen((data) {
      try {
        debugPrint("🔔 Live Notification: $data");

        // SMART NOTIFICATION LOGIC
        // If this is a message notification and we are currently in that chat, suppress it
        if (data['type'] == 'message') {
          final notifConvId =
              data['conversation_id']?.toString() ??
              data['conversationId']?.toString();
          final activeConvId = ChatService().activeConversationId;

          if (notifConvId != null &&
              activeConvId != null &&
              notifConvId.toString().trim().toLowerCase() ==
                  activeConvId.toString().trim().toLowerCase()) {
            debugPrint("🔕 Suppressing notification for active chat");
            return;
          }
        }

        // Deduplication: Check if ID already exists (if ID provided)
        // Note: Live notifications usually don't have ID until saved DB,
        // but payload might have 'notification' object or 'reference_id'

        // Add to top
        _notifications.insert(0, data);

        // Increment unread
        _unreadCount++;
        _unreadCountController.add(_unreadCount);
        _notificationsController.add(_notifications);
        _newNotificationController.add(data);
      } catch (e) {
        debugPrint("❌ Error processing notification: $e");
      }
    });
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

  /// 🧮 Helper: Count Unread
  void _countUnread() {
    _unreadCount = _notifications.where((n) => n['is_read'] == false).length;
  }
}
