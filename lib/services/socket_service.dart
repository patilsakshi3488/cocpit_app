import 'dart:async';
import 'package:flutter/foundation.dart';
// ignore: library_prefixes
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api_config.dart';

/// Service responsible for managing the WebSocket connection and exposing
/// real-time events via Streams.
class SocketService {
  // Singleton instance
  static final SocketService _instance = SocketService._internal();

  factory SocketService() => _instance;

  SocketService._internal();

  IO.Socket? _socket;

  // Stream Controllers
  final _connectionStatusController = StreamController<bool>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _stopTypingController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _userStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _messageReadController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _messageDeletedController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Public Streams
  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  Stream<Map<String, dynamic>> get onNewMessage => _messageController.stream;
  Stream<Map<String, dynamic>> get onNotification =>
      _notificationController.stream;
  Stream<Map<String, dynamic>> get onTyping => _typingController.stream;
  Stream<Map<String, dynamic>> get onStopTyping => _stopTypingController.stream;
  Stream<Map<String, dynamic>> get onUserStatusChanged =>
      _userStatusController.stream;
  Stream<Map<String, dynamic>> get onMessageRead =>
      _messageReadController.stream;
  Stream<Map<String, dynamic>> get onMessageDeleted =>
      _messageDeletedController.stream;

  bool get isConnected => _socket?.connected ?? false;

  /// Connect to the WebSocket Server
  /// [accessToken] is required for authentication.
  void connect(String accessToken) {
    if (_socket != null && _socket!.connected) {
      debugPrint('ℹ️ [Socket] Already connected. Skipping initialization.');
      return;
    }

    // Ensure clean URL (remove /api suffix if present to get base host)
    final String baseUrl = ApiConfig.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
    debugPrint('🔌 [Socket] Connecting to: $baseUrl');

    try {
      _socket = IO.io(
        baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket']) // Force WebSocket only for stability
            .setAuth({'token': accessToken}) // Auth Token
            .enableAutoConnect() // Enable auto-connect
            .setReconnectionAttempts(10) // Retry connection
            .setReconnectionDelay(1000)
            .build(),
      );

      _setupListeners();
      _socket!.connect();
    } catch (e) {
      debugPrint('❌ [Socket] Initialization Error: $e');
    }
  }

  void _setupListeners() {
    if (_socket == null) return;

    // --- Lifecycle Events ---
    _socket!.onConnect((_) {
      debugPrint('✅ [Socket] Connected: ${_socket!.id}');
      _connectionStatusController.add(true);
    });

    _socket!.onDisconnect((data) {
      debugPrint('🔌 [Socket] Disconnected: $data');
      _connectionStatusController.add(false);
    });

    _socket!.onConnectError((data) {
      debugPrint('❌ [Socket] Connection Error: $data');
      _connectionStatusController.add(false);
    });

    _socket!.onError((data) {
      debugPrint('⚠️ [Socket] Error: $data');
    });

    // --- Data Events (Server -> Client) ---

    // 1. New Message
    _socket!.on('newMessage', (data) {
      if (data != null && data is Map) {
        debugPrint('📩 [Socket] New Message received');
        _messageController.add(Map<String, dynamic>.from(data));
      }
    });

    // 2. Notifications (Follows, Likes, etc.)
    _socket!.on('notification', (data) {
      if (data != null && data is Map) {
        debugPrint('🔔 [Socket] Notification received: ${data['type']}');
        _notificationController.add(Map<String, dynamic>.from(data));
      }
    });

    // 3. User Status (Presence)
    _socket!.on('userStatusChanged', (data) {
      if (data != null && data is Map) {
        _userStatusController.add(Map<String, dynamic>.from(data));
      }
    });

    // 4. Typing Indicators
    _socket!.on('isTyping', (data) {
      if (data != null && data is Map) {
        _typingController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('stoppedTyping', (data) {
      if (data != null && data is Map) {
        _stopTypingController.add(Map<String, dynamic>.from(data));
      }
    });

    // 5. Message Updates (Read/Deleted)
    _socket!.on('messagesRead', (data) {
      if (data != null && data is Map) {
        _messageReadController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('messageDeleted', (data) {
      if (data != null && data is Map) {
        _messageDeletedController.add(Map<String, dynamic>.from(data));
      }
    });
  }

  /// Disconnect the socket
  void disconnect() {
    if (_socket != null) {
      debugPrint('🔌 [Socket] Disconnecting...');
      _socket!.disconnect();
      _socket!.close(); // Dispose underlying resources
      _socket = null;
      _connectionStatusController.add(false);
    }
  }

  // ============================================
  // 📤 EMIT EVENTS (Client -> Server)
  // ============================================

  /// Join a conversation room (Required to receive typing events)
  void joinConversation(String conversationId) {
    if (isConnected) {
      _socket!.emit('joinConversation', {'conversationId': conversationId});
    }
  }

  /// Notify that user started typing
  void startTyping(String conversationId) {
    if (isConnected) {
      _socket!.emit('typing', {'conversationId': conversationId});
    }
  }

  /// Notify that user stopped typing
  void stopTyping(String conversationId) {
    if (isConnected) {
      _socket!.emit('stopTyping', {'conversationId': conversationId});
    }
  }

  /// Dispose: Close all streams (Call when app is terminated, usually not needed for Singleton)
  void dispose() {
    disconnect();
    _connectionStatusController.close();
    _messageController.close();
    _notificationController.close();
    _typingController.close();
    _stopTypingController.close();
    _userStatusController.close();
    _messageReadController.close();
    _messageDeletedController.close();
  }
}
