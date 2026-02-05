import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/chat_service.dart';
import '../../services/secure_storage.dart';
import 'widgets/shared_post_preview.dart';
import '../../utils/message_transformer.dart';
import '../../services/group_chat_service.dart';
import 'group_details_screen.dart';

class GroupChatScreen extends StatefulWidget {
  final Map<String, dynamic> conversation;

  const GroupChatScreen({super.key, required this.conversation});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ChatService _chatService = ChatService();
  final GroupChatService _groupService = GroupChatService();
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? _groupDetails;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoadingMore = false;
  StreamSubscription? _msgSub;
  String? _myUserId;
  String? _myUserName;
  bool _isAdmin = false;
  bool _isMember = true;
  Timer? _typingTimer;
  DateTime? _lastTypingTime;
  Map<String, dynamic>? _replyingToMessage;
  Set<String> _typingUserIds = {};
  StreamSubscription? _typingSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initChat();
  }

  Future<void> _initChat() async {
    _myUserId = await AppSecureStorage.getCurrentUserId();
    _myUserName = await AppSecureStorage.getUserName();

    // 1. Enter the chat immediately
    await _chatService.enterChat(widget.conversation['conversation_id']);

    // 2. Load group details separately
    _loadGroupDetails();

    // 3. Setup messages
    _messages = _chatService.currentMessages;
    if (mounted) setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    _msgSub = _chatService.activeMessages.listen((updatedMessages) {
      if (!mounted) return;

      // 🚫 Stop processing messages if user is no longer a member
      if (!_isMember) {
        return;
      }

      final bool isHistoryLoad =
          updatedMessages.length > _messages.length &&
          updatedMessages.isNotEmpty &&
          _messages.isNotEmpty &&
          updatedMessages.last['message_id'] == _messages.last['message_id'];

      final bool isNewMessage =
          updatedMessages.length > _messages.length &&
          updatedMessages.isNotEmpty &&
          _messages.isNotEmpty &&
          updatedMessages.last['message_id'] != _messages.last['message_id'];

      final double oldMaxScroll = _scrollController.hasClients
          ? _scrollController.position.maxScrollExtent
          : 0;
      final double currentScroll = _scrollController.hasClients
          ? _scrollController.offset
          : 0;

      final bool wasAtBottom =
          _scrollController.hasClients && (oldMaxScroll - currentScroll) < 50;

      setState(() {
        _messages = updatedMessages;
        _isLoadingMore = _chatService.isLoadingMore;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;

        if (isHistoryLoad) {
          final double newMaxScroll =
              _scrollController.position.maxScrollExtent;
          final double heightDiff = newMaxScroll - oldMaxScroll;
          _scrollController.jumpTo(currentScroll + heightDiff);
        } else if (isNewMessage) {
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
      if (mounted) setState(() => _typingUserIds = typingIds);
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
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    _msgSub?.cancel();
    _typingSub?.cancel();
    _typingTimer?.cancel();
    _chatService.pause();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _chatService.sendStopTyping();
      _chatService.pause();
    } else if (state == AppLifecycleState.resumed) {
      _chatService.sendStopTyping();
      _chatService.pause();
    }
  }

  Future<void> _loadGroupDetails() async {
    final freshDetails = await _groupService.getGroupDetails(
      widget.conversation['conversation_id'],
    );

    if (mounted && freshDetails != null) {
      final members = freshDetails['members'] as List?;
      final wasMember = _isMember;
      final isNowMember =
          members?.any(
            (m) => (m['id'] ?? m['user_id']).toString() == _myUserId,
          ) ??
          false;

      setState(() {
        _groupDetails = freshDetails;
        _isAdmin = freshDetails['admin_id']?.toString() == _myUserId;
        _isMember = isNowMember;
      });

      // If membership status changed from member to non-member, disconnect
      if (wasMember && !isNowMember) {
        _handleMembershipLoss();
      }
    }
  }

  void _handleMembershipLoss() {
    // Cancel message subscription to stop receiving new messages
    _msgSub?.cancel();
    _typingSub?.cancel();

    // Leave the chat room on the backend
    _chatService.pause();

    // Clear typing timer
    _typingTimer?.cancel();
  }

  bool get _canSend {
    // 1. Must have details loaded
    if (_groupDetails == null) return false;
    // 2. Must be a member
    return _isMember;
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
      _lastTypingTime = null;
    });
  }

  void _showMessageActions(Map<String, dynamic> msg) {
    if (msg['type'] == 'system') return;

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
              ListTile(
                leading: const Icon(Icons.bug_report, color: Colors.amber),
                title: const Text('Debug Info'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Message Data"),
                      content: SingleChildScrollView(
                        child: SelectableText(msg.toString()),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Close"),
                        ),
                      ],
                    ),
                  );
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

      // Call GroupChatService to send media to group endpoint (Parity with Website)
      await _groupService.sendGroupMediaMessage(
        groupId: widget.conversation['conversation_id'],
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
    final senderName = isMe
        ? 'You'
        : (_replyingToMessage!['sender_name'] ?? 'User');

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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    _typingTimer?.cancel();
    _chatService.sendStopTyping();
    _lastTypingTime = null;

    // Call GroupChatService to send message to group endpoint (Parity with Website)
    await _groupService.sendGroupMessage(
      widget.conversation['conversation_id'],
      text,
    );

    _scrollToBottom();
    setState(() {
      _replyingToMessage = null;
    });
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  bool _isSystemMessageByContent(String text) {
    // Check for common system message patterns
    final systemPatterns = [
      ' created the group',
      ' was added to the group',
      ' were added to the group',
      ' left the group',
      ' was removed from the group',
      ' updated group icon',
      ' updated the group name',
      ' updated the group description',
    ];

    return systemPatterns.any((pattern) => text.contains(pattern));
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

  Widget _buildSystemMessage(Map<String, dynamic> msg, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            MessageTransformer.getSystemText(
              msg,
              _myUserId,
              myUserName: _myUserName,
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    if (_typingUserIds.isEmpty) return const SizedBox.shrink();

    final members = widget.conversation['members'] as List? ?? [];
    List<String> names = [];
    for (var id in _typingUserIds) {
      final member = members.firstWhere(
        (m) => m['id'].toString() == id,
        orElse: () => null,
      );
      if (member != null) {
        names.add(member['name'] ?? 'Someone');
      }
    }

    if (names.isEmpty) return const SizedBox.shrink();

    String text;
    if (names.length == 1) {
      text = "${names[0]} is typing...";
    } else if (names.length == 2) {
      text = "${names[0]} and ${names[1]} are typing...";
    } else {
      text = "${names.length} people are typing...";
    }

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
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showGroupDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailsScreen(
          conversation: _groupDetails ?? widget.conversation,
          isAdmin: _isAdmin,
          onMembersChanged: () async {
            // Refresh conversation data immediately
            final newDetails = await _groupService.getGroupDetails(
              widget.conversation['conversation_id'],
            );
            if (newDetails != null && mounted) {
              setState(() {
                _groupDetails = newDetails;
                final members = newDetails['members'] as List?;
                _isAdmin = newDetails['admin_id']?.toString() == _myUserId;
                _isMember =
                    members?.any((m) => m['id'].toString() == _myUserId) ??
                    false;
              });
            }
          },
          onLeave: () {
            setState(() => _isMember = false);
          },
        ),
      ),
    );
  }

  Widget _buildMessageInput(ThemeData theme) {
    if (!_isMember) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Center(
            child: Text(
              _groupDetails == null
                  ? "Loading group details..."
                  : "You are no longer a participant in this group",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (!_canSend) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Center(
            child: Text(
              "Loading...",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.add_circle, color: theme.primaryColor, size: 28),
              onPressed: _pickMedia,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    0.3,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  style: theme.textTheme.bodyMedium,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: _onTextChanged,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _sendMessage,
              ),
            ),
          ],
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: colorScheme.onSurface),
        title: GestureDetector(
          onTap: _showGroupDetails,
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey,
                backgroundImage:
                    _groupDetails?['avatar_url'] != null ||
                        _groupDetails?['group_avatar'] != null
                    ? NetworkImage(
                        _groupDetails?['avatar_url'] ??
                            _groupDetails?['group_avatar'],
                      )
                    : null,
                child:
                    _groupDetails?['avatar_url'] == null &&
                        _groupDetails?['group_avatar'] == null
                    ? const Icon(Icons.group, size: 20, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _groupDetails?['conversation_name'] ??
                          _groupDetails?['group_name'] ??
                          widget.conversation['conversation_name'] ??
                          widget.conversation['group_name'] ??
                          'Group',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "${(_groupDetails?['members'] as List?)?.length ?? 0} members",
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: colorScheme.onSurface),
            onPressed: _showGroupDetails,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (!_isLoadingMore &&
                    scrollInfo.metrics.pixels < 100 &&
                    _chatService.hasMore) {
                  _isLoadingMore = true;
                  _chatService.loadMoreMessages();
                }
                return false;
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_chatService.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  final bool hasMore = _chatService.hasMore;

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

                  final msgIndex = hasMore ? index - 1 : index;
                  final msg = _messages[msgIndex];

                  // Check if this is a system message
                  final String textContent = msg['text_content'] ?? '';
                  final bool isSystemMessage =
                      msg['type'] == 'system' ||
                      msg['message_type'] == 'system' ||
                      (msg['action_type'] != null &&
                          msg['action_type'] != '') ||
                      _isSystemMessageByContent(textContent);

                  if (isSystemMessage) {
                    return _buildSystemMessage(msg, theme);
                  }

                  final bool isMe =
                      msg['sender_id'] == _myUserId || msg['sender_id'] == 'me';

                  String time = '';
                  DateTime? msgDate;
                  if (msg['created_at'] != null) {
                    try {
                      final dt = DateTime.parse(msg['created_at']).toLocal();
                      msgDate = dt;
                      final hour = dt.hour > 12
                          ? dt.hour - 12
                          : (dt.hour == 0 ? 12 : dt.hour);
                      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
                      final minute = dt.minute.toString().padLeft(2, '0');
                      time = "$hour:$minute $amPm";
                    } catch (e) {}
                  }

                  bool showDateHeader = false;
                  if (msgDate != null) {
                    if (msgIndex == 0) {
                      showDateHeader = true;
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

                  bool isFirstInGroup = true;
                  bool isLastInGroup = true;
                  const groupingThreshold = Duration(minutes: 5);

                  if (msgIndex > 0) {
                    final prevMsg = _messages[msgIndex - 1];
                    final bool sameSender =
                        prevMsg['sender_id'] == msg['sender_id'] ||
                        (prevMsg['sender_id'] == 'me' && isMe);
                    if (sameSender &&
                        msgDate != null &&
                        prevMsg['created_at'] != null) {
                      final prevDate = DateTime.parse(
                        prevMsg['created_at'],
                      ).toLocal();
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
                    if (sameSender &&
                        msgDate != null &&
                        nextMsg['created_at'] != null) {
                      final nextDate = DateTime.parse(
                        nextMsg['created_at'],
                      ).toLocal();
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
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (!isMe && isFirstInGroup)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 12,
                                  bottom: 4,
                                ),
                                child: Text(
                                  msg['sender_name'] ?? 'User',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              children: [
                                if (isMe &&
                                    (msg['status'] == 'sending' ||
                                        msg['status'] == 'failed'))
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: msg['status'] == 'failed'
                                        ? GestureDetector(
                                            onTap: () =>
                                                _chatService.retryMessage(
                                                  msg['message_id'],
                                                ),
                                            child: const Icon(
                                              Icons.error_outline,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                          )
                                        : const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                  ),
                                Flexible(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (msg['status'] == 'failed')
                                        _chatService.retryMessage(
                                          msg['message_id'],
                                        );
                                    },
                                    onLongPress: () => _showMessageActions(msg),
                                    child: Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            0.7,
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
                                        gradient:
                                            isMe && msg['status'] != 'failed'
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
                                                        : null))
                                            : theme
                                                  .colorScheme
                                                  .surfaceContainer,
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
                                              color: Colors.black.withOpacity(
                                                0.05,
                                              ),
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                        ],
                                        border: isMe
                                            ? (msg['status'] == 'failed'
                                                  ? Border.all(
                                                      color: Colors.red,
                                                    )
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
                                            _buildMediaPreview(
                                              msg,
                                              isMe,
                                              theme,
                                            ),
                                          if (msg['shared_post'] != null)
                                            SharedPostPreview(
                                              sharedPost: msg['shared_post'],
                                              isMe: isMe,
                                              messageText: msg['text_content'],
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
                                                    mainAxisSize:
                                                        MainAxisSize.min,
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
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          _buildReplyPreview(theme),
          _buildTypingIndicator(theme),
          _buildMessageInput(theme),
        ],
      ),
    );
  }
}
