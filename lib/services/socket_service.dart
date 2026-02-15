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

  // ⚠️ Remove any auto-initialization. Connection must be explicit.

  IO.Socket? _socket;
  String? _currentToken;
  final List<VoidCallback> _onConnectQueue = [];

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
  Stream<bool> get connectionStatus async* {
    yield isConnected;
    await for (final status in _connectionStatusController.stream) {
      yield status;
    }
  }

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
  String? get socketId => _socket?.id;
  String? get currentBaseUrl => _socket?.io.uri;

  /// Connect to the WebSocket Server
  /// [accessToken] is required for authentication.
  void connect(String accessToken, {bool forceReconnect = false}) {
    final token = accessToken.trim();

    // Check if duplicate connection attempt
    if (_socket != null && _socket!.connected) {
      // If same token, skip. If different token, we MUST reconnect.
      if (_currentToken == token && !forceReconnect) {
        debugPrint('ℹ️ [Socket] Already connected with same token. Skipping.');
        return;
      }

      debugPrint(
        '🔄 [Socket] Token changed or forceReconnect requested. Reconnecting...',
      );
      disconnect();
    }

    // Ensure clean URL (remove /api suffix if present to get base host)
    final String baseUrl = ApiConfig.baseUrl.replaceAll(RegExp(r'/api/?$'), '');

    // Mask token for security in logs
    final maskedToken = token.length > 10
        ? "${token.substring(0, 5)}...${token.substring(token.length - 5)}"
        : "***";

    debugPrint('🔌 [Socket] Connecting to: $baseUrl with token: $maskedToken');

    try {
      _currentToken = token;
      _currentToken = token;
      _socket = IO.io(
        baseUrl,
        IO.OptionBuilder()
            .setTransports([
              'websocket',
            ]) // ⚡ FORCE WEBSOCKET (Mobile Best Practice)
            .disableAutoConnect() // 🛑 MANUAL CONNECT ONLY
            .enableForceNew()
            .setAuth({'token': token})
            .setQuery({'token': token})
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .setPath('/socket.io')
            .setReconnectionAttempts(double.infinity) // ♾️ TRY FOREVER
            .setReconnectionDelay(2000) // Start with 2s delay
            .setReconnectionDelayMax(10000) // Cap at 10s
            .setTimeout(60000) // 60s Connection Timeout
            .build(),
      );

      // 🐛 DEBUG: Mobile network fix
      _socket!.io.options?['pingTimeout'] = 60000;
      _socket!.io.options?['pingInterval'] = 25000;

      _setupListeners();

      _setupListeners();

      // Raw Logger & Heartbeat logic
      _socket!.onAny((event, data) {
        // debugPrint("📡 [Socket] RAW EVENT: $event | DATA: $data");
        // If we get ANY event, the socket is definitely working even if internal state is weird
        if (!isConnected) {
          debugPrint(
            "💓 [Socket] Heartbeat event received: $event. Forcing isConnected = true",
          );
          _connectionStatusController.add(true);
        }
      });

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

      // Process Queued Actions
      while (_onConnectQueue.isNotEmpty) {
        final action = _onConnectQueue.removeAt(0);
        action();
      }
    });

    _socket!.onDisconnect((data) {
      debugPrint('🔌 [Socket] Disconnected: $data');
      _connectionStatusController.add(false);
    });

    _socket!.onConnectError((data) {
      debugPrint('❌ [Socket] Connection Error (Detailed): $data');
      // If it's an object, try to see more info
      if (data != null && data is Map) {
        debugPrint('❌ [Socket] Error Message: ${data['message']}');
      }
      _connectionStatusController.add(false); // Explicitly fail on error
    });

    _socket!.onError((data) {
      debugPrint('⚠️ [Socket] General Error: $data');
      _connectionStatusController.add(false);
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
      debugPrint('👥 [Socket] User Status Change Received: $data');
      if (data != null && data is Map) {
        _userStatusController.add(Map<String, dynamic>.from(data));
      }
    });

    // 4. Typing Indicators
    void handleTyping(data) {
      debugPrint('⌨️ [Socket] typing Received: $data');
      if (data != null && data is Map) {
        _typingController.add(Map<String, dynamic>.from(data));
      }
    }

    _socket!.on('isTyping', handleTyping);
    _socket!.on('typing', handleTyping);

    void handleStopTyping(data) {
      debugPrint('🛑 [Socket] stopTyping Received: $data');
      if (data != null && data is Map) {
        _stopTypingController.add(Map<String, dynamic>.from(data));
      }
    }

    _socket!.on('stoppedTyping', handleStopTyping);
    _socket!.on('stopTyping', handleStopTyping);

    // 6. Initial Online Users (Hypothetical - catching common patterns)
    _socket!.on('onlineUsers', (data) {
      debugPrint('👥 [Socket] Initial Online Users Received: $data');
      if (data != null && data is List) {
        // Transform to map format expected by PresenceService or just emit special event
        // For now, let's reuse _userStatusController if we can, or add a new one.
        // Actually, let's just emit individual status changes for simpler handling downstream
        for (var user in data) {
          _userStatusController.add({
            'userId': user['userId'] ?? user['id'],
            'status': 'online',
          });
        }
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
  /// Disconnect the socket
  void disconnect() {
    if (_socket != null) {
      debugPrint('🔌 [Socket] Disconnecting...');
      _socket!.disconnect();
      _currentToken = null;
      _connectionStatusController.add(false);
    }
  }

  void pause() {
    if (_socket != null && _socket!.connected) {
      debugPrint('⏸️ [Socket] Pausing (disconnecting)...');
      _socket!.disconnect();
    }
  }

  void resume() {
    if (_socket != null && !_socket!.connected) {
      debugPrint('▶️ [Socket] Resuming (connecting)...');
      _socket!.connect();
    }
  }

  // ============================================
  // 📤 EMIT EVENTS (Client -> Server)
  // ============================================

  void _safeEmit(String event, dynamic data) {
    if (isConnected) {
      debugPrint('📤 [Socket] Emitting $event: $data');
      _socket!.emit(event, data);
    } else {
      debugPrint('⏳ [Socket] Not connected. Queuing $event.');
      _onConnectQueue.add(() => _socket!.emit(event, data));
    }
  }

  /// Join a conversation room (Required to receive typing events)
  void joinConversation(String conversationId) {
    _safeEmit('joinConversation', {'conversationId': conversationId});
  }

  /// Notify that user started typing
  void startTyping(String conversationId) {
    _safeEmit('typing', {'conversationId': conversationId});
  }

  /// Notify that user stopped typing
  void stopTyping(String conversationId) {
    _safeEmit('stopTyping', {'conversationId': conversationId});
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
