import 'dart:async';
import 'socket_service.dart';
import 'social_service.dart';

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

  // Internal state
  List<Map<String, dynamic>> _currentMessages = [];
  String? _activeConversationId;
  String? get activeConversationId => _activeConversationId;

  // --- Socket Listeners ---
  void _listenToSocket() {
    _socketService.onNewMessage.listen((data) {
      if (_activeConversationId != null &&
          data['conversation_id'] == _activeConversationId) {
        _handleNewMessage(data);
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
    }
  }

  // --- Public API ---

  /// Enter a chat: Loads history and subscribes to updates
  Future<void> enterChat(String conversationId) async {
    _activeConversationId = conversationId;
    _currentMessages = []; // Clear previous
    _activeMessagesController.add([]); // Notify UI

    // 1. Join Room for Typing Indicators
    _socketService.joinConversation(conversationId);

    // 2. Fetch History
    final messages = await _socialService.getMessages(conversationId);
    if (_activeConversationId == conversationId) {
      _currentMessages = messages;
      _activeMessagesController.add(List.from(_currentMessages));

      // 3. Mark as Read
      await _socialService.markAsRead(conversationId);
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
}
