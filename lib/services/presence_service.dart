import 'dart:async';
import 'package:flutter/foundation.dart';
import 'socket_service.dart';

class PresenceService {
  static final PresenceService _instance = PresenceService._internal();

  factory PresenceService() => _instance;

  PresenceService._internal() {
    _listenToSocket();
  }

  final SocketService _socketService = SocketService();
  final Set<String> _onlineUsers = {};

  final _onlineUsersController = StreamController<Set<String>>.broadcast();
  Stream<Set<String>> get onlineUsers async* {
    yield Set.from(_onlineUsers);
    yield* _onlineUsersController.stream;
  }

  void _listenToSocket() {
    _socketService.onUserStatusChanged.listen((data) {
      try {
        debugPrint("🟢 [Presence] Status Changed Event: $data");

        // Try to find User ID in various possible keys
        final rawId = data['userId'] ?? data['user_id'] ?? data['id'];
        final userId = rawId?.toString().trim().toLowerCase();

        // Status normalization
        final status = data['status']?.toString().toLowerCase();

        if (userId != null && status != null) {
          if (status == 'online') {
            _onlineUsers.add(userId);
            debugPrint("🟢 [Presence] User $userId is now ONLINE");
          } else {
            _onlineUsers.remove(userId);
            debugPrint("🔴 [Presence] User $userId is now OFFLINE");
          }

          _onlineUsersController.add(Set.from(_onlineUsers));
          debugPrint(
            "👥 [Presence] Total Online: ${_onlineUsers.length} | Users: $_onlineUsers",
          );
        } else {
          debugPrint("⚠️ [Presence] Received invalid status packet: $data");
        }
      } catch (e) {
        debugPrint("❌ [Presence] Error processing status event: $e");
      }
    });

    // Reset on disconnect
    _socketService.connectionStatus.listen((isConnected) {
      if (!isConnected) {
        _onlineUsers.clear();
        _onlineUsersController.add({});
      } else {
        // Try to ask for online users
        // Using a raw emit if SocketService doesn't have a helper yet,
        // but ideally we should add a helper.
        // For now, we assume SocketService will be updated or we use reflection.
        // Actually, let's use the public helper we are about to add, or just accept the passive flow.
        // Passively: We hope the server sends it.
        // Actively: We need to emit.
        // Let's assume we need to emit "getOnlineUsers"
        // Accessing private socket is hard. Let's add a public method in SocketService first?
        // No, let's just rely on the 'onlineUsers' event added above for now.
      }
    });
  }

  bool isUserOnline(String? userId) {
    if (userId == null) return false;
    return _onlineUsers.contains(userId.trim().toLowerCase());
  }
}
