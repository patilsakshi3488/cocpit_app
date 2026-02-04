import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'socket_service.dart';
import 'social_service.dart';
import 'notification_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();

  factory ChatService() => _instance;

  ChatService._internal() {
    _listenToSocket();
    fetchTotalUnreadCount();
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

  // 🔴 Unread Badge Count (Conversations)
  final _unreadCountController = StreamController<int>.broadcast();
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  // Track IDs of conversations with unread messages
  final Set<String> _unreadConversationIds = {};
  int get totalUnreadCount => _unreadConversationIds.length;

  // Internal state
  List<Map<String, dynamic>> _currentMessages = [];
  String? _activeConversationId;
  String? get activeConversationId => _activeConversationId;
  List<Map<String, dynamic>> get currentMessages => _currentMessages;

  // --- Socket Listeners ---
  void _listenToSocket() {
    // 1. New Message
    _socketService.onNewMessage.listen((data) {
      // payload normalization (handle both snake_case and camelCase)
      String? incomingConvId =
          (data['conversation_id'] ?? data['conversationId'])
              ?.toString()
              .trim()
              .toLowerCase();

      // Fallback: Check if message is nested
      if (incomingConvId == null && data['message'] is Map) {
        incomingConvId =
            (data['message']['conversation_id'] ??
                    data['message']['conversationId'])
                ?.toString()
                .trim()
                .toLowerCase();
      }
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
        if (incomingConvId != null) {
          debugPrint(
            "❌ NO MATCH: Active Chat Not Updated. Marking conversation $incomingConvId as unread.",
          );
          _unreadConversationIds.add(incomingConvId);
          _unreadCountController.add(_unreadConversationIds.length);
        }
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
      // payload: { conversation_id, reader_id, messageIds: [], read_at: timestamp }
      final convId = (data['conversation_id'] ?? data['conversationId'])
          ?.toString();
      if (convId == _activeConversationId) {
        final messageIds = List<String>.from(
          data['message_ids'] ?? data['messageIds'] ?? [],
        );
        final readAt = data['read_at'] ?? DateTime.now().toIso8601String();

        bool changed = false;
        for (var msg in _currentMessages) {
          final mId = (msg['message_id'] ?? msg['id'])?.toString();
          if (mId != null && messageIds.contains(mId)) {
            if (msg['read_at'] == null) {
              msg['read_at'] = readAt;
              changed = true;
            }
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

  // Pagination State
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  final int _pageSize = 20;

  /// Enter a chat: Loads initial history and subscribes to updates
  Future<void> enterChat(String conversationId) async {
    _activeConversationId = conversationId;
    _currentMessages = []; // Clear previous
    _activeMessagesController.add([]); // Notify UI
    _currentTypingUsers.clear();
    _typingUsersController.add({});
    _hasMore = true;
    _isLoadingMore = false;

    // 1. Join Room for Typing Indicators
    _socketService.joinConversation(conversationId);

    // 2. Fetch Initial History
    await _loadMessages(initial: true);

    // 3. Mark as Read (Backend)
    if (_activeConversationId == conversationId) {
      await _socialService.markAsRead(conversationId);

      // 4. Clear local notifications if any
      NotificationService().clearNotificationsForConversation(conversationId);

      // 5. Update global unread count (Remove this conversation from unread set)
      _unreadConversationIds.remove(conversationId.trim().toLowerCase());
      _unreadCountController.add(_unreadConversationIds.length);

      // Also fetch fresh from server to be sure
      fetchTotalUnreadCount();
    }
  }

  /// Load more messages (Pagination)
  Future<void> loadMoreMessages() async {
    if (!_hasMore || _isLoadingMore || _activeConversationId == null) return;
    await _loadMessages(initial: false);
  }

  /// Internal message loader
  Future<void> _loadMessages({required bool initial}) async {
    if (_activeConversationId == null) return;

    _isLoadingMore = true;
    // Broadcast loading state if you had a separate stream for it,
    // or just let UI check isLoadingMore getter (reactive update needed?)
    // Actually, UI usually just triggers and waits.
    // For proper UI spinner, we might want to emit the list again or just rely on Future completion.

    try {
      String? beforeCursor;
      if (!initial && _currentMessages.isNotEmpty) {
        // Use oldest message timestamp as cursor
        // List is Oldest -> Newest (index 0 is Oldest)
        beforeCursor = _currentMessages.first['created_at'];
      }

      final newMessages = await _socialService.getMessages(
        _activeConversationId!,
        before: beforeCursor,
        limit: _pageSize,
      );

      if (_activeConversationId == null) return; // Left chat while loading

      if (newMessages.length < _pageSize) {
        _hasMore = false;
      }

      if (initial) {
        _currentMessages = newMessages;
      } else {
        // Prepend older messages
        // Dedup just in case
        for (var msg in newMessages.reversed) {
          final msgId = (msg['message_id'] ?? msg['id'])?.toString();
          final exists = _currentMessages.any(
            (m) => (m['message_id'] ?? m['id'])?.toString() == msgId,
          );
          if (!exists) {
            _currentMessages.insert(0, msg);
          }
        }
      }

      _activeMessagesController.add(List.from(_currentMessages));
    } catch (e) {
      debugPrint("❌ Error loading messages: $e");
    } finally {
      _isLoadingMore = false;
    }
  }

  /// Fetch and update total unread messages count
  Future<void> fetchTotalUnreadCount() async {
    try {
      final conversations = await _socialService.getConversations();
      _unreadConversationIds.clear();

      for (var c in conversations) {
        final unread = c['unread_count'] as int? ?? 0;
        final id = (c['conversation_id'] ?? c['id'])
            ?.toString()
            .trim()
            .toLowerCase();

        if (unread > 0 && id != null) {
          _unreadConversationIds.add(id);
        }
      }
      _unreadCountController.add(_unreadConversationIds.length);
    } catch (e) {
      debugPrint("❌ Error fetching unread count: $e");
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
      'target_user_id': targetUserId, // Needed for retry
      'created_at': DateTime.now().toIso8601String(),
      'status': 'sending',
    };

    _currentMessages.add(optimisticMessage);
    _activeMessagesController.add(List.from(_currentMessages));

    // 🛰️ Quick Network Check for "Immediate" failure feedback
    if (!await _hasNetwork()) {
      _markAsFailed(tempId);
      _activeMessagesController.add(List.from(_currentMessages));
      return;
    }

    try {
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
          // Should not happen if optimistic is there, but safety:
          _currentMessages.add(result);
        }
      } else {
        // Handle explicit null failure
        _markAsFailed(tempId);
      }
    } catch (e) {
      debugPrint("❌ Send message failed: $e");
      _markAsFailed(tempId);
    }

    _activeMessagesController.add(List.from(_currentMessages));
  }

  /// Send a Media Message (Image/Video)
  Future<void> sendMediaMessage({
    required String targetUserId,
    required File file,
    required String mediaType, // 'image' or 'video'
  }) async {
    if (_activeConversationId == null) return;

    final tempId = "media_temp_${DateTime.now().millisecondsSinceEpoch}";
    final optimisticMessage = {
      'message_id': tempId,
      'sender_id': 'me',
      'target_user_id': targetUserId,
      'created_at': DateTime.now().toIso8601String(),
      'status': 'sending',
      'local_media_path': file.path,
      'media_type': mediaType,
    };

    _currentMessages.add(optimisticMessage);
    _activeMessagesController.add(List.from(_currentMessages));

    // 🛰️ Quick Check
    if (!await _hasNetwork()) {
      _markAsFailed(tempId);
      _activeMessagesController.add(List.from(_currentMessages));
      return;
    }

    try {
      final result = await _socialService.sendMediaMessage(
        targetUserId: targetUserId,
        file: file,
        mediaType: mediaType,
      );

      if (result != null) {
        final index = _currentMessages.indexWhere(
          (m) => m['message_id'] == tempId,
        );
        if (index != -1) {
          _currentMessages[index] = result;
        }
      } else {
        _markAsFailed(tempId);
      }
    } catch (e) {
      debugPrint("❌ Media upload failed: $e");
      _markAsFailed(tempId);
    }
    _activeMessagesController.add(List.from(_currentMessages));
  }

  void _markAsFailed(String tempId) {
    final index = _currentMessages.indexWhere((m) => m['message_id'] == tempId);
    if (index != -1) {
      _currentMessages[index]['status'] = 'failed';
    }
  }

  /// 🛰️ Connectivity helper
  Future<bool> _hasNetwork() async {
    if (kIsWeb) return true; // InternetAddress not available on web
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 2));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Retry a failed message
  Future<void> retryMessage(String tempId) async {
    final index = _currentMessages.indexWhere((m) => m['message_id'] == tempId);
    if (index == -1) return;

    final msg = _currentMessages[index];
    if (msg['status'] != 'failed') return;

    // 1. Reset status to sending
    msg['status'] = 'sending';
    _activeMessagesController.add(List.from(_currentMessages));

    // 🛰️ Quick Check
    if (!await _hasNetwork()) {
      _markAsFailed(tempId);
      _activeMessagesController.add(List.from(_currentMessages));
      return;
    }

    // 2. Extract original data (assuming it's preserved in msg)
    // We need targetUserId.
    // Issue: The original `sendMessage` had targetUserId as arg, but `_currentMessages` only has message data.
    // Solution: We need to know who we are talking to.
    // Efficient fix: Use `_activeConversationId` via `SocialService` if possible, OR
    // we need to look up the other participant.
    // Actually `sendMessage` API takes `targetUserId`.
    // In a 1-on-1 chat, we can infer target from the active conversation context?
    // Start simple: We might need to store `target_user_id` in the optimistic message for retries.

    final targetUserId = msg['target_user_id'];
    final content = msg['text_content'];
    final localPath = msg['local_media_path'];
    final mediaType = msg['media_type'];

    try {
      if (localPath != null && File(localPath).existsSync()) {
        // --- RETRY MEDIA ---
        final result = await _socialService.sendMediaMessage(
          targetUserId: targetUserId ?? '',
          file: File(localPath),
          mediaType: mediaType ?? 'image',
        );
        if (result != null) {
          final idx = _currentMessages.indexWhere(
            (m) => m['message_id'] == tempId,
          );
          if (idx != -1) _currentMessages[idx] = result;
        } else {
          _markAsFailed(tempId);
        }
      } else if (content != null) {
        // --- RETRY TEXT ---
        final result = await _socialService.sendMessage(
          targetUserId: targetUserId ?? '',
          content: content,
        );

        if (result != null) {
          final idx = _currentMessages.indexWhere(
            (m) => m['message_id'] == tempId,
          );
          if (idx != -1) _currentMessages[idx] = result;
        } else {
          _markAsFailed(tempId);
        }
      } else {
        _markAsFailed(tempId);
      }
    } catch (e) {
      debugPrint("❌ Retry failed: $e");
      _markAsFailed(tempId);
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
