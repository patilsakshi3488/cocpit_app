import 'dart:async';
import 'package:flutter/material.dart';
import '../bottom_navigation.dart';
// import '../../widgets/app_top_bar.dart'; // Removed
import '../../services/social_service.dart';
import '../../services/socket_service.dart';
import '../../services/chat_service.dart';
import '../../services/presence_service.dart'; // Import PresenceService
import '../../services/secure_storage.dart'; // Helpful for user ID
import '../../widgets/time_ago_widget.dart';
import '../profile/public_profile_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SocialService _socialService = SocialService();
  final SocketService _socketService = SocketService();
  final PresenceService _presenceService =
      PresenceService(); // Init PresenceService
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
    // Normalized ID extraction
    final convId =
        (messageData['conversation_id'] ?? messageData['conversationId'])
            ?.toString();

    if (convId == null) return;

    setState(() {
      final index = _conversations.indexWhere(
        (c) => c['conversation_id'] == convId,
      );

      if (index != -1) {
        // Update existing conversation
        final conv = _conversations.removeAt(index);
        conv['last_message_text'] = messageData['text_content'];
        conv['updated_at'] =
            messageData['created_at'] ?? DateTime.now().toIso8601String();
        conv['timeAgo'] = "Just now";

        // Only increment unread if we are NOT currently in this chat
        final activeId = ChatService().activeConversationId
            ?.toString()
            .trim()
            .toLowerCase();
        final incomingId = convId.toString().trim().toLowerCase();

        final isActive = activeId != null && activeId == incomingId;

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

            // 🔌 Connection Status Banner
            StreamBuilder<bool>(
              stream: _socketService.connectionStatus,
              builder: (context, snapshot) {
                final isConnected = snapshot.data ?? _socketService.isConnected;
                if (isConnected) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  color: Colors.red.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: const Center(
                    child: Text(
                      "Connecting to real-time server...",
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                );
              },
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<Set<String>>(
                      stream: _presenceService.onlineUsers,
                      builder: (context, snapshot) {
                        final onlineUsers = snapshot.data ?? {};
                        return RefreshIndicator(
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
                                      'id': conv['other_user_id']?.toString(),
                                      'name':
                                          conv['other_user_name'] ?? 'Unknown',
                                      'avatar': conv['other_user_avatar'],
                                      'headline':
                                          conv['other_user_headline'] ?? '',
                                    };

                                    return _ChatTile(
                                      name: otherUser['name'],
                                      avatarUrl: otherUser['avatar'],
                                      role: otherUser['headline'],
                                      message:
                                          conv['last_message_text'] ?? 'Draft',
                                      dateTime: DateTime.tryParse(
                                        (conv['updated_at'] ??
                                                conv['updatedAt'] ??
                                                conv['created_at'] ??
                                                '')
                                            .toString(),
                                      ),
                                      fallbackTime: conv['timeAgo'] ?? '',
                                      unreadCount: conv['unread_count'] ?? 0,
                                      color:
                                          Colors.primaries[index %
                                              Colors.primaries.length],
                                      isOnline: onlineUsers.contains(
                                        otherUser['id']
                                            ?.toString()
                                            .trim()
                                            .toLowerCase(),
                                      ), // Connect Presence
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
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: -1),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final String role;
  final String message;
  final DateTime? dateTime; // Changed from time
  final String fallbackTime;
  final int unreadCount;
  final Color color;
  final bool isOnline;
  final VoidCallback onTap;

  const _ChatTile({
    required this.name,
    this.avatarUrl,
    required this.role,
    required this.message,
    this.dateTime,
    required this.fallbackTime,
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
                  // Header Row: Name + Role + Time (Aligned)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
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
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 2,
                        ), // Minor tweak for alignment
                        child: dateTime != null
                            ? TimeAgoWidget(
                                dateTime: dateTime!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              )
                            : Text(
                                fallbackTime,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
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
  Timer? _typingTimer;
  DateTime? _lastTypingTime;

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
    _typingTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    if (text.isEmpty) {
      // Logic for empty could be handled, but stopTyping usually via timer
      return;
    }

    final now = DateTime.now();
    if (_lastTypingTime == null ||
        now.difference(_lastTypingTime!) > const Duration(seconds: 2)) {
      _chatService.sendTyping();
      _lastTypingTime = now;
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _chatService.sendStopTyping();
      _lastTypingTime = null; // Reset ensures next type triggers immediately
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    _typingTimer?.cancel();
    _chatService.sendStopTyping();
    _lastTypingTime = null;

    // Delegate to ChatService (Optimistic + API)
    await _chatService.sendMessage(widget.otherUser['id'], text);
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Widget _buildDateHeader(DateTime date, ThemeData theme) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    String label;
    if (dateOnly == today) {
      label = "Today";
    } else if (dateOnly == yesterday) {
      label = "Yesterday";
    } else {
      // Simple format: MMM dd, yyyy
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      label = "${months[date.month - 1]} ${date.day}, ${date.year}";
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: theme.dividerColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final otherName = widget.otherUser['name'];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: colorScheme.onSurface),
        title: StreamBuilder<Set<String>>(
          stream: PresenceService().onlineUsers,
          builder: (context, snapshot) {
            final onlineUsers = snapshot.data ?? {};
            final String? otherId = widget.otherUser['id']
                ?.toString()
                .trim()
                .toLowerCase();
            final isOnline = otherId != null && onlineUsers.contains(otherId);

            return GestureDetector(
              onTap: () {
                if (otherId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PublicProfileScreen(userId: otherId),
                    ),
                  );
                }
              },
              child: Row(
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
                      if (isOnline)
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
                      Text(
                        isOnline ? "Online" : "Offline",
                        style: TextStyle(
                          color: isOnline ? Colors.green : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
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

                // Show latest messages at the bottom (reverse view)
                // Assuming API returns [Oldest -> Newest]
                // We reverse the list for the UI so Index 0 is Newest (Bottom)
                final reversedMessages = messages.reversed.toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  reverse: true, // Auto-scroll to bottom behavior
                  itemCount: reversedMessages.length,
                  itemBuilder: (context, index) {
                    final msg = reversedMessages[index];
                    // Determine if 'Me' based on sender_id == _myUserId
                    final bool isMe =
                        msg['sender_id'] == _myUserId ||
                        msg['sender_id'] == 'me';

                    // Format time properly (UTC -> Local)
                    String time = '';
                    if (msg['created_at'] != null) {
                      try {
                        final dt = DateTime.parse(msg['created_at']).toLocal();
                        final hour = dt.hour > 12
                            ? dt.hour - 12
                            : (dt.hour == 0 ? 12 : dt.hour);
                        final amPm = dt.hour >= 12 ? 'PM' : 'AM';
                        final minute = dt.minute.toString().padLeft(2, '0');
                        time = "$hour:$minute $amPm";
                      } catch (e) {
                        // Fallback
                      }
                    }

                    // Date Header Logic
                    bool showDateHeader = false;
                    DateTime? msgDate;

                    if (msg['created_at'] != null) {
                      msgDate = DateTime.parse(msg['created_at']).toLocal();
                    }

                    if (msgDate != null) {
                      // Check if next item (which is OLDER, index + 1) is different day
                      if (index == reversedMessages.length - 1) {
                        showDateHeader = true; // Oldest message
                      } else {
                        final nextMsg = reversedMessages[index + 1];
                        if (nextMsg['created_at'] != null) {
                          final nextDate = DateTime.parse(
                            nextMsg['created_at'],
                          ).toLocal();
                          if (!_isSameDay(msgDate, nextDate)) {
                            showDateHeader = true;
                          }
                        }
                      }
                    }

                    return Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (showDateHeader && msgDate != null)
                          _buildDateHeader(msgDate, theme),
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(
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
                              if (isMe) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.done_all,
                                  size: 16,
                                  color: msg['read_at'] != null
                                      ? Colors
                                            .white // Blue doesn't look good on primary color, usually white or light blue
                                      : Colors.white.withOpacity(0.5),
                                ),
                              ],
                            ],
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
          StreamBuilder<Set<String>>(
            stream: _chatService.typingUsers,
            builder: (context, snapshot) {
              final typingUsers = snapshot.data ?? {};
              // Filter out 'me' just in case, though backend/service logic handles it
              if (typingUsers.isEmpty) return const SizedBox.shrink();

              // For 1-on-1, ideally check if otherUser.id is in set
              // But 'typingUsers' from service logic already filters to active conversation events
              // And service logic *currently* adds *senderId*.
              // So we check if our friend is typing.

              final isFriendTyping = typingUsers.contains(
                widget.otherUser['id'],
              );

              if (!isFriendTyping) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "${widget.otherUser['name']} is typing...",
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              );
            },
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
                onChanged: _onTextChanged,
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
