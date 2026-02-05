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
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'widgets/shared_post_preview.dart';
import 'dart:io';
import 'group_chat_screen.dart';
import 'create_group_screen.dart';
import '../../services/group_chat_service.dart';

enum ChatFilter { all, personal, groups }

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final SocketService _socketService = SocketService();
  final PresenceService _presenceService =
      PresenceService(); // Init PresenceService
  StreamSubscription? _msgSub;
  // final String _currentUserId = "";

  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _invitations = [];
  bool _isLoading = true;
  ChatFilter _currentFilter = ChatFilter.all;
  StreamSubscription? _socketSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadConversations();
    _setupSocketListeners();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    final convs = await SocialService().getConversations();
    final invites = await GroupChatService().getPendingInvitations();
    if (mounted) {
      setState(() {
        _conversations = convs;
        _invitations = invites;
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

    // 🔔 Listen for invitations
    _socketSub = _socketService.onNotification.listen((data) {
      if (!mounted) return;
      if (data['type'] == 'group_invitation') {
        _loadConversations();
      }
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
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _msgSub?.cancel();
    _socketSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("📱 [ChatScreen] Resumed from background. Resyncing...");
      _loadConversations();
      ChatService().resync();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      ChatService().pause();
    }
  }

  Widget _buildInvitationsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            "Group Invitations",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        ..._invitations.map((invite) {
          return ListTile(
            leading: CircleAvatar(child: Text(invite['group_name'][0])),
            title: Text(invite['group_name']),
            subtitle: Text('Invited by ${invite['inviter_name']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () async {
                    final groupId = invite['group_id']?.toString();
                    if (groupId == null) return;

                    final success = await GroupChatService().acceptInvitation(
                      groupId,
                    );
                    if (success) {
                      await _loadConversations();
                      // Find the new conversation and navigate
                      final newConv = _conversations.firstWhere(
                        (c) =>
                            c['is_group'] == true &&
                            c['conversation_id'] == groupId,
                        orElse: () => {},
                      );
                      if (newConv.isNotEmpty && mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                GroupChatScreen(conversation: newConv),
                          ),
                        );
                      }
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () async {
                    final groupId = invite['group_id']?.toString();
                    if (groupId != null) {
                      await GroupChatService().rejectInvitation(groupId);
                      _loadConversations();
                    }
                  },
                ),
              ],
            ),
          );
        }).toList(),
        const Divider(),
      ],
    );
  }

  Widget _buildFilterTabs(ThemeData theme) {
    return Row(
      children: [
        _buildFilterChip("All", ChatFilter.all, theme),
        const SizedBox(width: 8),
        _buildFilterChip("Chats", ChatFilter.personal, theme),
        const SizedBox(width: 8),
        _buildFilterChip("Groups", ChatFilter.groups, theme),
      ],
    );
  }

  Widget _buildFilterChip(String label, ChatFilter filter, ThemeData theme) {
    final isSelected = _currentFilter == filter;
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => setState(() => _currentFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor
              : colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
          ).then((_) => _loadConversations());
        },
        backgroundColor: theme.primaryColor,
        child: const Icon(Icons.group_add, color: Colors.white),
      ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Messages",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.add_circle_outline_rounded,
                          color: theme.primaryColor,
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CreateGroupScreen(),
                            ),
                          ).then((_) => _loadConversations());
                        },
                        tooltip: "Create Group",
                      ),
                    ],
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
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (v) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFilterTabs(theme),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<Set<String>>(
                      stream: _presenceService.onlineUsers,
                      builder: (context, snapshot) {
                        final onlineUsers = snapshot.data ?? {};
                        final searchQuery = _searchController.text
                            .toLowerCase()
                            .trim();

                        final filteredConversations = _conversations.where((c) {
                          // 1. Tab Filtering
                          final isGroup = c['is_group'] == true;
                          bool matchesTab = true;
                          if (_currentFilter == ChatFilter.personal)
                            matchesTab = !isGroup;
                          else if (_currentFilter == ChatFilter.groups)
                            matchesTab = isGroup;

                          if (!matchesTab) return false;

                          // 2. Search Filtering
                          if (searchQuery.isEmpty) return true;

                          final name =
                              (isGroup
                                      ? (c['conversation_name'] ??
                                            c['group_name'] ??
                                            'Group Chat')
                                      : (c['other_user_name'] ?? 'Unknown'))
                                  .toString()
                                  .toLowerCase();

                          return name.contains(searchQuery);
                        }).toList();

                        if (filteredConversations.isEmpty &&
                            _invitations.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  searchQuery.isEmpty
                                      ? Icons.chat_bubble_outline
                                      : Icons.search_off,
                                  size: 64,
                                  color: colorScheme.onSurfaceVariant
                                      .withOpacity(0.2),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  searchQuery.isEmpty
                                      ? "No conversations yet"
                                      : "No results for \"$searchQuery\"",
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: _loadConversations,
                          child:
                              filteredConversations.isEmpty &&
                                  _invitations.isEmpty
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
                                  itemCount:
                                      filteredConversations.length +
                                      (_invitations.isNotEmpty ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (_invitations.isNotEmpty && index == 0) {
                                      return _buildInvitationsSection(theme);
                                    }

                                    final convIndex = _invitations.isNotEmpty
                                        ? index - 1
                                        : index;
                                    final conv =
                                        filteredConversations[convIndex];
                                    final bool isGroup =
                                        conv['is_group'] == true;
                                    final Map<String, dynamic> otherUser =
                                        isGroup
                                        ? {
                                            'id': conv['conversation_id'],
                                            'name':
                                                conv['conversation_name'] ??
                                                conv['group_name'] ??
                                                'Group Chat',
                                            'avatar': conv['group_avatar'],
                                            'headline': 'Group',
                                          }
                                        : {
                                            'id': conv['other_user_id']
                                                ?.toString(),
                                            'name':
                                                conv['other_user_name'] ??
                                                'Unknown',
                                            'avatar': conv['other_user_avatar'],
                                            'headline':
                                                conv['other_user_headline'] ??
                                                '',
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
                                      ),
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => isGroup
                                                ? GroupChatScreen(
                                                    conversation: conv,
                                                  )
                                                : PersonalChatScreen(
                                                    conversationId:
                                                        conv['conversation_id'],
                                                    otherUser: otherUser,
                                                  ),
                                          ),
                                        );
                                        _loadConversations();
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

class _PersonalChatScreenState extends State<PersonalChatScreen>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoadingMore = false;
  StreamSubscription? _msgSub;
  String? _myUserId;
  Timer? _typingTimer;
  DateTime? _lastTypingTime;
  Map<String, dynamic>? _replyingToMessage;
  bool _isOtherTyping = false;
  StreamSubscription? _typingSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initChat();
  }

  Future<void> _initChat() async {
    _myUserId = await AppSecureStorage.getCurrentUserId();
    await _chatService.enterChat(widget.conversationId);

    // Initial Load
    _messages = _chatService
        .currentMessages; // Ensure getter exists or use activeMessages.first
    if (mounted) setState(() {});

    // Jump to bottom initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    // Listen to updates
    _msgSub = _chatService.activeMessages.listen((updatedMessages) {
      if (!mounted) return;

      // Detect if we added older messages (History Load)
      // Heuristic: If count increased and last message is same, we added to top.
      final bool isHistoryLoad =
          updatedMessages.length > _messages.length &&
          updatedMessages.isNotEmpty &&
          _messages.isNotEmpty &&
          updatedMessages.last['message_id'] == _messages.last['message_id'];

      // Detect if new message arrived (at bottom)
      final bool isNewMessage =
          updatedMessages.length > _messages.length &&
          updatedMessages.isNotEmpty &&
          _messages.isNotEmpty &&
          updatedMessages.last['message_id'] != _messages.last['message_id'];

      // Capture pre-update scroll extent
      final double oldMaxScroll = _scrollController.hasClients
          ? _scrollController.position.maxScrollExtent
          : 0;
      final double currentScroll = _scrollController.hasClients
          ? _scrollController.offset
          : 0;

      // Check if we were at the bottom (sticky logic)
      final bool wasAtBottom =
          _scrollController.hasClients && (oldMaxScroll - currentScroll) < 50;

      setState(() {
        _messages = updatedMessages;
        _isLoadingMore = _chatService.isLoadingMore;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;

        if (isHistoryLoad) {
          // Calculate height difference
          final double newMaxScroll =
              _scrollController.position.maxScrollExtent;
          final double heightDiff = newMaxScroll - oldMaxScroll;

          // Maintain visual position by jumping down by heightDiff
          _scrollController.jumpTo(currentScroll + heightDiff);
        } else if (isNewMessage) {
          // If was at bottom or it's my message, scroll to bottom
          final bool isMe =
              updatedMessages.last['sender_id'] == _myUserId ||
              updatedMessages.last['sender_id'] == 'me';
          if (wasAtBottom || isMe) {
            _scrollToBottom();
          }
        }
      });
    });

    _typingSub = _chatService.typingUsers.listen((typingIds) {
      if (mounted) {
        setState(() {
          _isOtherTyping = typingIds.contains(
            widget.otherUser['id'].toString(),
          );
        });
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatService.leaveChat();
    _msgSub?.cancel();
    _typingSub?.cancel();
    _typingTimer?.cancel();
    _messageFocusNode.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("📱 [PersonalChat] Resumed. Resyncing data...");
      _chatService.resync();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Clear typing indicator when leaving app
      _typingTimer?.cancel();
      _chatService.sendStopTyping();
      _chatService.pause();
    }
  }

  void _onTextChanged(String text) {
    if (text.isEmpty) return;

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

  void _showMessageActions(Map<String, dynamic> msg) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy'),
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: msg['text_content'] ?? ''),
                  );
                  if (mounted) {
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  setState(() {
                    _replyingToMessage = msg;
                  });
                  Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickMedia() async {
    final ImagePicker picker = ImagePicker();
    final XFile? media = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () async {
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (context.mounted) Navigator.pop(context, image);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text('Video Library'),
                onTap: () async {
                  final XFile? video = await picker.pickVideo(
                    source: ImageSource.gallery,
                  );
                  if (context.mounted) Navigator.pop(context, video);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () async {
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (context.mounted) Navigator.pop(context, image);
                },
              ),
            ],
          ),
        );
      },
    );

    if (media != null) {
      final file = File(media.path);
      final String path = media.path.toLowerCase();
      final String mediaType = path.endsWith('.mp4') || path.endsWith('.mov')
          ? 'video'
          : 'image';

      _chatService.sendMediaMessage(
        targetUserId: widget.otherUser['id'],
        file: file,
        mediaType: mediaType,
      );
    }
  }

  Widget _buildMediaPreview(
    Map<String, dynamic> msg,
    bool isMe,
    ThemeData theme,
  ) {
    final String? mediaUrl = msg['media_url'];
    final String? localPath = msg['local_media_path'];
    final String? mediaType = msg['media_type'];
    final bool isVideo = mediaType == 'video';

    return GestureDetector(
      onTap: () => _openFullScreenMedia(msg),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: const BoxConstraints(maxHeight: 200, minWidth: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withOpacity(0.05),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (localPath != null && File(localPath).existsSync())
              Image.file(
                File(localPath),
                fit: BoxFit.cover,
                width: double.infinity,
              )
            else if (mediaUrl != null)
              Image.network(
                mediaUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (ctx, err, stack) {
                  return const Center(
                    child: Icon(Icons.broken_image, size: 40),
                  );
                },
              )
            else
              const Center(child: CircularProgressIndicator()),
            if (isVideo)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 30,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openFullScreenMedia(Map<String, dynamic> msg) {
    // Basic full screen viewer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
          body: Center(
            child: InteractiveViewer(
              child:
                  msg['local_media_path'] != null &&
                      File(msg['local_media_path']).existsSync()
                  ? Image.file(File(msg['local_media_path']))
                  : msg['media_url'] != null
                  ? Image.network(msg['media_url'])
                  : const Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 100,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNestedReply(
    Map<String, dynamic> msg,
    bool isMe,
    ThemeData theme,
  ) {
    if (msg['reply_to'] == null) return const SizedBox.shrink();

    final reply = msg['reply_to'];
    final senderName = reply['author_name'] ?? 'User';
    final text = reply['text_content'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.black.withOpacity(0.1)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.white : theme.primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            senderName,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isMe ? Colors.white70 : theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isMe ? Colors.white60 : null,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview(ThemeData theme) {
    if (_replyingToMessage == null) return const SizedBox.shrink();

    final isMe =
        _replyingToMessage!['sender_id'] == 'me' ||
        _replyingToMessage!['sender_id'] == _myUserId;
    final senderName = isMe ? 'You' : (widget.otherUser['name'] ?? 'User');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(left: BorderSide(color: theme.primaryColor, width: 4)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply,
            size: 16,
            color: theme.primaryColor.withOpacity(0.7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  senderName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  _replyingToMessage!['text_content'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              setState(() {
                _replyingToMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    if (!_isOtherTyping) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            "${widget.otherUser['name']} is typing...",
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    _typingTimer?.cancel();
    _chatService.sendStopTyping();
    _lastTypingTime = null;

    // Delegate to ChatService (Optimistic + API)
    await _chatService.sendMessage(widget.otherUser['id'], text);
    // Force scroll to bottom immediately on send (optimistic)
    _scrollToBottom();
    setState(() {
      _replyingToMessage = null;
    });
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
                      StreamBuilder<Set<String>>(
                        stream: _chatService.typingUsers,
                        builder: (context, snapshot) {
                          final typingUsers = snapshot.data ?? {};
                          final isTyping =
                              otherId != null && typingUsers.contains(otherId);

                          if (isTyping) {
                            return Text(
                              "Typing...",
                              style: TextStyle(
                                color: theme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }

                          return Text(
                            isOnline ? "Online" : "Offline",
                            style: TextStyle(
                              color: isOnline ? Colors.green : Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
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
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                // Detect TOP scroll (pixels close to 0) to load MORE HISTORY
                if (!_isLoadingMore &&
                    scrollInfo.metrics.pixels < 100 && // 100px from top
                    _chatService.hasMore) {
                  _isLoadingMore = true; // Local lock
                  _chatService.loadMoreMessages();
                }
                return false;
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                reverse: false, // 🛑 Standard Top-Down
                // +1 for loader at Top (Index 0) if hasMore
                itemCount: _messages.length + (_chatService.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  final bool hasMore = _chatService.hasMore;

                  // If hasMore, Index 0 is Loader
                  if (hasMore && index == 0) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }

                  // Adjust index: If hasMore, Msg Index 0 is Widget Index 1
                  final msgIndex = hasMore ? index - 1 : index;
                  final msg = _messages[msgIndex];

                  final bool isMe =
                      msg['sender_id'] == _myUserId || msg['sender_id'] == 'me';

                  // Format time
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
                    } catch (e) {}
                  }

                  // Date Header Logic (Compare with PREVIOUS message in list order)
                  bool showDateHeader = false;
                  DateTime? msgDate;
                  if (msg['created_at'] != null) {
                    msgDate = DateTime.parse(msg['created_at']).toLocal();
                  }

                  if (msgDate != null) {
                    if (msgIndex == 0) {
                      showDateHeader = true; // First message always shows date
                    } else {
                      final prevMsg = _messages[msgIndex - 1];
                      if (prevMsg['created_at'] != null) {
                        final prevDate = DateTime.parse(
                          prevMsg['created_at'],
                        ).toLocal();
                        if (!_isSameDay(msgDate, prevDate)) {
                          showDateHeader = true;
                        }
                      }
                    }
                  }

                  // Grouping Logic
                  bool isFirstInGroup = true;
                  bool isLastInGroup = true;
                  const groupingThreshold = Duration(minutes: 5);

                  if (msgIndex > 0) {
                    final prevMsg = _messages[msgIndex - 1];
                    final bool sameSender =
                        prevMsg['sender_id'] == msg['sender_id'] ||
                        (prevMsg['sender_id'] == 'me' && isMe);
                    DateTime? prevDate;
                    if (prevMsg['created_at'] != null) {
                      prevDate = DateTime.parse(
                        prevMsg['created_at'],
                      ).toLocal();
                    }
                    if (sameSender && msgDate != null && prevDate != null) {
                      final diff = msgDate.difference(prevDate).abs();
                      if (diff < groupingThreshold &&
                          _isSameDay(msgDate, prevDate)) {
                        isFirstInGroup = false;
                      }
                    }
                  }

                  if (msgIndex < _messages.length - 1) {
                    final nextMsg = _messages[msgIndex + 1];
                    final bool sameSender =
                        nextMsg['sender_id'] == msg['sender_id'] ||
                        (nextMsg['sender_id'] == 'me' && isMe);
                    DateTime? nextDate;
                    if (nextMsg['created_at'] != null) {
                      nextDate = DateTime.parse(
                        nextMsg['created_at'],
                      ).toLocal();
                    }
                    if (sameSender && msgDate != null && nextDate != null) {
                      final diff = nextDate.difference(msgDate).abs();
                      if (diff < groupingThreshold &&
                          _isSameDay(msgDate, nextDate)) {
                        isLastInGroup = false;
                      }
                    }
                  }

                  return Column(
                    children: [
                      if (isFirstInGroup && showDateHeader && msgDate != null)
                        _buildDateHeader(msgDate, theme),

                      Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Status Indicator (Left of bubble for 'me')
                            if (isMe &&
                                (msg['status'] == 'sending' ||
                                    msg['status'] == 'failed'))
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: msg['status'] == 'failed'
                                    ? GestureDetector(
                                        onTap: () {
                                          if (msg['message_id'] != null) {
                                            _chatService.retryMessage(
                                              msg['message_id'],
                                            );
                                          }
                                        },
                                        child: const Icon(
                                          Icons.error_outline,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                      )
                                    : SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: theme.primaryColor.withOpacity(
                                            0.5,
                                          ),
                                        ),
                                      ),
                              ),

                            Flexible(
                              child: GestureDetector(
                                onTap: () {
                                  if (msg['status'] == 'failed' &&
                                      msg['message_id'] != null) {
                                    _chatService.retryMessage(
                                      msg['message_id'],
                                    );
                                  }
                                },
                                onLongPress: () => _showMessageActions(msg),
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  margin: EdgeInsets.only(
                                    bottom: isLastInGroup ? 8 : 2,
                                    top: isFirstInGroup ? 4 : 0,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: isMe && msg['status'] != 'failed'
                                        ? LinearGradient(
                                            colors: [
                                              theme.primaryColor,
                                              theme.primaryColor
                                                  .withBlue(255)
                                                  .withGreen(100),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    color: isMe
                                        ? (msg['status'] == 'failed'
                                              ? Colors.red.withOpacity(0.1)
                                              : (msg['status'] == 'sending'
                                                    ? theme.primaryColor
                                                          .withOpacity(0.7)
                                                    : null)) // Null because gradient is used
                                        : colorScheme.surfaceContainer,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(
                                        !isMe && !isFirstInGroup ? 6 : 20,
                                      ),
                                      bottomLeft: Radius.circular(
                                        !isMe && !isLastInGroup ? 6 : 20,
                                      ),
                                      topRight: Radius.circular(
                                        isMe && !isFirstInGroup ? 6 : 20,
                                      ),
                                      bottomRight: Radius.circular(
                                        isMe && !isLastInGroup ? 6 : 20,
                                      ),
                                    ),
                                    boxShadow: [
                                      if (!isMe)
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                    ],
                                    border: isMe
                                        ? (msg['status'] == 'failed'
                                              ? Border.all(color: Colors.red)
                                              : null)
                                        : Border.all(
                                            color: theme.dividerColor
                                                .withOpacity(0.5),
                                          ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      if (msg['reply_to'] != null)
                                        _buildNestedReply(msg, isMe, theme),
                                      if (msg['media_url'] != null ||
                                          msg['local_media_path'] != null)
                                        _buildMediaPreview(msg, isMe, theme),
                                      if (msg['shared_post'] != null)
                                        Column(
                                          crossAxisAlignment: isMe
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                          children: [
                                            SharedPostPreview(
                                              sharedPost: msg['shared_post'],
                                              isMe: isMe,
                                              messageText: msg['text_content'],
                                            ),
                                            if (isLastInGroup)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 4,
                                                  right: 12,
                                                  left: 12,
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      time,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: isMe
                                                            ? theme
                                                                  .colorScheme
                                                                  .onPrimary
                                                                  .withOpacity(
                                                                    0.7,
                                                                  )
                                                            : theme
                                                                  .colorScheme
                                                                  .onSurface
                                                                  .withOpacity(
                                                                    0.5,
                                                                  ),
                                                      ),
                                                    ),
                                                    if (isMe &&
                                                        msg['status'] !=
                                                            'sending' &&
                                                        msg['status'] !=
                                                            'failed') ...[
                                                      const SizedBox(width: 4),
                                                      Icon(
                                                        msg['read_at'] != null
                                                            ? Icons.done_all
                                                            : Icons.done,
                                                        size: 15,
                                                        color:
                                                            msg['read_at'] !=
                                                                null
                                                            ? Colors.blueAccent
                                                            : Colors.white
                                                                  .withOpacity(
                                                                    0.8,
                                                                  ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      if (msg['shared_post'] == null)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                msg['text_content'] ?? '',
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: isMe
                                                          ? (msg['status'] ==
                                                                    'failed'
                                                                ? Colors.red
                                                                : theme
                                                                      .colorScheme
                                                                      .onPrimary)
                                                          : theme
                                                                .colorScheme
                                                                .onSurface,
                                                    ),
                                              ),
                                            ),
                                            if (isLastInGroup) ...[
                                              const SizedBox(width: 8),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    time,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: isMe
                                                          ? (msg['status'] ==
                                                                    'failed'
                                                                ? Colors.red
                                                                : theme
                                                                      .colorScheme
                                                                      .onPrimary
                                                                      .withOpacity(
                                                                        0.7,
                                                                      ))
                                                          : theme
                                                                .colorScheme
                                                                .onSurface
                                                                .withOpacity(
                                                                  0.5,
                                                                ),
                                                    ),
                                                  ),
                                                  if (isMe &&
                                                      msg['status'] !=
                                                          'sending' &&
                                                      msg['status'] !=
                                                          'failed') ...[
                                                    const SizedBox(width: 4),
                                                    Icon(
                                                      msg['read_at'] != null
                                                          ? Icons.done_all
                                                          : Icons.done,
                                                      size: 15,
                                                      color:
                                                          msg['read_at'] != null
                                                          ? Colors.blueAccent
                                                          : Colors.white
                                                                .withOpacity(
                                                                  0.8,
                                                                ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          // Reply Preview
          _buildReplyPreview(theme),
          _buildTypingIndicator(theme),
          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.add_circle,
                      color: theme.primaryColor.withOpacity(0.8),
                      size: 28,
                    ),
                    onPressed: _pickMedia,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: theme.dividerColor.withOpacity(0.1),
                        ),
                      ),
                      child: Material(
                        type: MaterialType.transparency,
                        child: TextField(
                          controller: _messageController,
                          focusNode: _messageFocusNode,
                          onChanged: _onTextChanged,
                          style: theme.textTheme.bodyMedium,
                          enableInteractiveSelection: true,
                          minLines: 1,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: "Type a message...",
                            hintStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.5),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
