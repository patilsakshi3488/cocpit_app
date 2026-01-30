import 'dart:async';
import 'package:flutter/foundation.dart';
import 'socket_service.dart';
import 'social_service.dart';
import 'notification_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();

  factory ChatService() => _instance;

  ChatService._internal() {
    _listenToSocket();
  }

  final SocketService _socketService = SocketService();
  final SocialService _socialService = SocialService();

  // Reactive Stream for the active conversation
  final _activeMessagesController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  Stream<List<Map<String, dynamic>>> get activeMessages =>
      _activeMessagesController.stream;

  // ⚡ Typing Indicators
  final _typingUsersController = StreamController<Set<String>>.broadcast();
  Stream<Set<String>> get typingUsers => _typingUsersController.stream;
  final Set<String> _currentTypingUsers = {};

  // Internal state
  List<Map<String, dynamic>> _currentMessages = [];
  String? _activeConversationId;
  String? get activeConversationId => _activeConversationId;

  // --- Socket Listeners ---
  void _listenToSocket() {
    // 1. New Message
    _socketService.onNewMessage.listen((data) {
      // payload normalization (handle both snake_case and camelCase)
      final incomingConvId = (data['conversation_id'] ?? data['conversationId'])
          ?.toString()
          .trim()
          .toLowerCase();
      final activeId = _activeConversationId?.toString().trim().toLowerCase();

      // Debug to see WHY it fails if it does
      if (activeId != null) {
        debugPrint(
          '🔍 CHECK: Incoming($incomingConvId) == Active($activeId)? ${incomingConvId == activeId}',
        );
      }

      if (activeId != null && incomingConvId == activeId) {
        debugPrint('🔔 SOCKET MSG: Matches active chat!');

        // --- Deduplication Check ---
        final msgId = (data['message_id'] ?? data['id'])?.toString();
        if (msgId != null) {
          final isDuplicate = _currentMessages.any(
            (m) => (m['message_id'] ?? m['id'])?.toString() == msgId,
          );
          if (isDuplicate) {
            debugPrint("♻️ SOCKET MSG: Duplicate ignored ($msgId)");
            return;
          }
        }

        // --- Key Normalization for UI ---
        final normalizedData = Map<String, dynamic>.from(data);
        // Ensure standard keys exist for UI components
        normalizedData['conversation_id'] ??= normalizedData['conversationId'];
        normalizedData['sender_id'] ??= normalizedData['senderId'];
        normalizedData['text_content'] ??=
            normalizedData['textContent'] ?? normalizedData['text'];
        normalizedData['created_at'] ??=
            normalizedData['createdAt'] ?? DateTime.now().toIso8601String();

        _currentMessages.add(normalizedData);
        _activeMessagesController.add(List.from(_currentMessages));

        // Mark as read immediately since user is watching
        _socialService.markAsRead(activeId);
      } else {
        debugPrint("❌ NO MATCH: Active Chat Not Updated");
      }
    });

    // 2. Typing Started
    _socketService.onTyping.listen((data) {
      final convId = (data['conversation_id'] ?? data['conversationId'])
          ?.toString();
      final senderId = (data['sender_id'] ?? data['senderId'])?.toString();
      // Ensure it's for the current chat and NOT me
      if (convId == _activeConversationId && senderId != null) {
        _currentTypingUsers.add(senderId);
        _typingUsersController.add(Set.from(_currentTypingUsers));
      }
    });

    // 3. Typing Stopped
    _socketService.onStopTyping.listen((data) {
      final convId = (data['conversation_id'] ?? data['conversationId'])
          ?.toString();
      final senderId = (data['sender_id'] ?? data['senderId'])?.toString();

      if (convId == _activeConversationId) {
        if (senderId != null) {
          _currentTypingUsers.remove(senderId);
        } else {
          _currentTypingUsers.clear();
        }
        _typingUsersController.add(Set.from(_currentTypingUsers));
      }
    });

    // 4. Message Read
    _socketService.onMessageRead.listen((data) {
      // payload: { conversation_id, reader_id, messageIds: [] }
      final convId = (data['conversation_id'] ?? data['conversationId'])
          ?.toString();
      if (convId == _activeConversationId) {
        final messageIds = List<String>.from(
          data['message_ids'] ?? data['messageIds'] ?? [],
        );
        bool changed = false;
        for (var msg in _currentMessages) {
          final mId = (msg['message_id'] ?? msg['id'])?.toString();
          if (mId != null && messageIds.contains(mId)) {
            msg['read_at'] = DateTime.now().toIso8601String();
            changed = true;
          }
        }
        if (changed) {
          _activeMessagesController.add(List.from(_currentMessages));
        }
      }
    });
  }

  void _handleNewMessage(Map<String, dynamic> message) {
    // Check for duplicates (optimistic UI might have added it)
    final existingIndex = _currentMessages.indexWhere(
      (m) => m['message_id'] == message['message_id'],
    );

    if (existingIndex == -1) {
      _currentMessages.add(message);
      _activeMessagesController.add(List.from(_currentMessages));
    } else {
      // Update existing (e.g. from 'sending' to 'sent') if needed
      // But usually optimistic keeps it until confirmed.
      // If the incoming message is the real one, we might want to replace the temp one?
      // For now, let's just ignore if ID matches.
    }
  }

  // --- Public API ---

  /// Enter a chat: Loads history and subscribes to updates
  Future<void> enterChat(String conversationId) async {
    _activeConversationId = conversationId;
    _currentMessages = []; // Clear previous
    _activeMessagesController.add([]); // Notify UI
    _currentTypingUsers.clear();
    _typingUsersController.add({});

    // 1. Join Room for Typing Indicators
    _socketService.joinConversation(conversationId);

    // 2. Fetch History
    final messages = await _socialService.getMessages(conversationId);
    if (_activeConversationId == conversationId) {
      _currentMessages = messages;
      _activeMessagesController.add(List.from(_currentMessages));

      // 3. Mark as Read (Backend)
      await _socialService.markAsRead(conversationId);

      // 4. Clear local notifications if any
      NotificationService().clearNotificationsForConversation(conversationId);
    }
  }

  /// Leave a chat: Clears active state
  void leaveChat() {
    _activeConversationId = null;
    _currentMessages = [];
  }

  /// Send Message with Optimistic Update
  Future<void> sendMessage(String targetUserId, String content) async {
    if (_activeConversationId == null) return;

    // 1. Optimistic Update
    final tempId = "temp_${DateTime.now().millisecondsSinceEpoch}";
    final optimisticMessage = {
      'message_id': tempId,
      'text_content': content,
      'sender_id': 'me', // UI should handle 'me' or actual ID check
      'created_at': DateTime.now().toIso8601String(),
      'status': 'sending',
    };

    _currentMessages.add(optimisticMessage);
    _activeMessagesController.add(List.from(_currentMessages));

    // 2. API Call
    final result = await _socialService.sendMessage(
      targetUserId: targetUserId,
      content: content,
    );

    // 3. Reconcile
    if (result != null) {
      final index = _currentMessages.indexWhere(
        (m) => m['message_id'] == tempId,
      );
      if (index != -1) {
        _currentMessages[index] = result;
      } else {
        _currentMessages.add(result);
      }
    } else {
      // Handle failure (remove or mark failed)
      _currentMessages.removeWhere((m) => m['message_id'] == tempId);
    }
    _activeMessagesController.add(List.from(_currentMessages));
  }

  /// ✍️ Notify Typing
  void sendTyping() {
    if (_activeConversationId != null) {
      _socketService.startTyping(_activeConversationId!);
    }
  }

  /// 🛑 Notify Stopped Typing
  void sendStopTyping() {
    if (_activeConversationId != null) {
      _socketService.stopTyping(_activeConversationId!);
    }
  }
}
