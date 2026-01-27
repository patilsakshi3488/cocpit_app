import 'dart:async';
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
  Stream<Set<String>> get onlineUsers => _onlineUsersController.stream;

  void _listenToSocket() {
    _socketService.onUserStatusChanged.listen((data) {
      final userId = data['userId'];
      final status = data['status'];

      if (userId != null && status != null) {
        if (status == 'online') {
          _onlineUsers.add(userId);
        } else {
          _onlineUsers.remove(userId);
        }
        _onlineUsersController.add(Set.from(_onlineUsers));
      }
    });

    // Reset on disconnect
    _socketService.connectionStatus.listen((isConnected) {
      if (!isConnected) {
        _onlineUsers.clear();
        _onlineUsersController.add({});
      }
    });
  }

  bool isUserOnline(String userId) {
    return _onlineUsers.contains(userId);
  }
}
