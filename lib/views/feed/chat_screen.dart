import 'dart:async';
import 'package:flutter/material.dart';
import '../bottom_navigation.dart';
// import '../../widgets/app_top_bar.dart'; // Removed
import '../../services/social_service.dart';
import '../../services/socket_service.dart';
import '../../services/chat_service.dart';
import '../../services/secure_storage.dart'; // Helpful for user ID

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SocialService _socialService = SocialService();
  final SocketService _socketService = SocketService();
  StreamSubscription? _msgSub;
  // final String _currentUserId = "";

  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _setupSocketListeners();
  }

  Future<void> _loadConversations() async {
    final data = await _socialService.getConversations();
    if (mounted) {
      setState(() {
        _conversations = data;
        _isLoading = false;
      });
    }
  }

  void _setupSocketListeners() {
    // 📨 Listen for new messages globally to update the list
    _msgSub = _socketService.onNewMessage.listen((data) {
      if (!mounted) return;
      _handleNewMessage(data);
    });
  }

  void _handleNewMessage(Map<String, dynamic> messageData) {
    // messageData: { conversation_id, text_content, created_at, ... }
    final convId = messageData['conversation_id'];

    if (convId == null) return;

    setState(() {
      final index = _conversations.indexWhere(
        (c) => c['conversation_id'] == convId,
      );

      if (index != -1) {
        // Update existing conversation
        final conv = _conversations.removeAt(index);
        conv['last_message_text'] = messageData['text_content'];
        conv['timeAgo'] = "Just now";

        // Only increment unread if we are NOT currently in this chat
        final isActive = ChatService().activeConversationId == convId;
        if (!isActive) {
          conv['unread_count'] = (conv['unread_count'] ?? 0) + 1;
        } else {
          conv['unread_count'] = 0; // Ensure it's cleared if active
        }

        // Move to top
        _conversations.insert(0, conv);
      } else {
        // New conversation? We might need to refresh list or fetch details
        _loadConversations();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _msgSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // Removed AppTopBar to match custom design
      body: SafeArea(
        child: Column(
          children: [
            // 🏷️ Custom Header & Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Messages",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(
                        0.3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: "Search messages...",
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (v) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadConversations,
                      child: _conversations.isEmpty
                          ? Center(
                              child: Text(
                                "No conversations yet",
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: _conversations.length,
                              itemBuilder: (context, index) {
                                final conv = _conversations[index];
                                final otherUser = {
                                  'id': conv['other_user_id'],
                                  'name': conv['other_user_name'] ?? 'Unknown',
                                  'avatar': conv['other_user_avatar'],
                                  'headline': conv['other_user_headline'] ?? '',
                                };

                                return _ChatTile(
                                  name: otherUser['name'],
                                  avatarUrl: otherUser['avatar'],
                                  role: otherUser['headline'],
                                  message: conv['last_message_text'] ?? 'Draft',
                                  time: conv['timeAgo'] ?? '',
                                  unreadCount: conv['unread_count'] ?? 0,
                                  color:
                                      Colors.primaries[index %
                                          Colors.primaries.length],
                                  isOnline:
                                      false, // TODO: Connect PresenceService
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PersonalChatScreen(
                                          conversationId:
                                              conv['conversation_id'],
                                          otherUser: otherUser,
                                        ),
                                      ),
                                    );
                                    // Reset unread count locally since user just read it
                                    if (mounted) {
                                      setState(() {
                                        _conversations[index]['unread_count'] =
                                            0;
                                      });
                                    }
                                    _loadConversations(); // Refresh from server to sync
                                  },
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 0),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final String role;
  final String message;
  final String time;
  final int unreadCount;
  final Color color;
  final bool isOnline;
  final VoidCallback onTap;

  const _ChatTile({
    required this.name,
    this.avatarUrl,
    required this.role,
    required this.message,
    required this.time,
    required this.unreadCount,
    required this.color,
    required this.isOnline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: color.withOpacity(0.2),
                  backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                      ? NetworkImage(avatarUrl!)
                      : null,
                  child: avatarUrl == null || avatarUrl!.isEmpty
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Name + Badge + Time
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),

                      if (role.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            role,
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],

                      const Spacer(),

                      Text(
                        time,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Message Row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: unreadCount > 0
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PersonalChatScreen extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic> otherUser; // {id, name, avatar, headline}

  const PersonalChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUser,
  });

  @override
  State<PersonalChatScreen> createState() => _PersonalChatScreenState();
}

class _PersonalChatScreenState extends State<PersonalChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();

  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    _myUserId = await AppSecureStorage.getCurrentUserId();
    _chatService.enterChat(widget.conversationId);
  }

  @override
  void dispose() {
    _chatService.leaveChat();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    // Delegate to ChatService (Optimistic + API)
    await _chatService.sendMessage(widget.otherUser['id'], text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final otherName = widget.otherUser['name'];
    final otherRole = widget.otherUser['headline'];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: colorScheme.onSurface),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey,
                  backgroundImage: widget.otherUser['avatar'] != null
                      ? NetworkImage(widget.otherUser['avatar'])
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  otherName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (otherRole != null)
                  Text(
                    otherRole,
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.call_outlined, color: colorScheme.onSurface),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.activeMessages,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Text("Say hi!", style: theme.textTheme.bodyMedium),
                  );
                }

                // Show latest at bottom: Reverse the list for the ListView
                final reversedMessages = messages.reversed.toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  reverse: true, // Start from bottom
                  itemCount: reversedMessages.length,
                  itemBuilder: (context, index) {
                    final msg = reversedMessages[index];
                    // Determine if 'Me' based on sender_id == _myUserId
                    final bool isMe =
                        msg['sender_id'] == _myUserId ||
                        msg['sender_id'] == 'me';

                    // Format time correctly (Convert UTC to Local)
                    String time = '';
                    if (msg['created_at'] != null) {
                      try {
                        final dt = DateTime.parse(msg['created_at']).toLocal();
                        final timeOfDay = TimeOfDay.fromDateTime(dt);
                        time = timeOfDay.format(context);
                      } catch (e) {
                        // Fallback
                      }
                    }

                    return Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? theme.primaryColor
                                : colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                            border: isMe
                                ? null
                                : Border.all(color: theme.dividerColor),
                          ),
                          child: Text(
                            msg['text_content'] ?? '',
                            style: TextStyle(
                              color: isMe
                                  ? Colors.white
                                  : colorScheme.onSurface,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: 12,
                            left: 4,
                            right: 4,
                          ),
                          child: Text(time, style: theme.textTheme.bodySmall),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(theme),
        ],
      ),
    );
  }

  Widget _buildMessageInput(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add, color: theme.primaryColor),
            onPressed: () {},
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.dividerColor),
              ),
              child: TextField(
                controller: _messageController,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: "Write a message...",
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send, color: theme.primaryColor),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
