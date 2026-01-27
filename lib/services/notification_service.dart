import 'dart:async';
import 'socket_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal() {
    _listenToSocket();
  }

  final SocketService _socketService = SocketService();

  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onNotification =>
      _notificationController.stream;

  void _listenToSocket() {
    _socketService.onNotification.listen((data) {
      // Just forward the data for now.
      // In a real app, we might update a badge count or show a local notification here.
      _notificationController.add(data);
    });
  }
}
