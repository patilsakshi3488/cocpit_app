import 'package:flutter/material.dart';
import '../../widgets/app_top_bar.dart';
import '../../services/notification_service.dart';
import '../../widgets/time_ago_widget.dart';
import '../../services/feed_service.dart';
import '../profile/public_profile_screen.dart';
import '../feed/post_detail_screen.dart';
import '../feed/chat_screen.dart'; // For PersonalChatScreen

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notificationService.loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const AppTopBar(searchType: SearchType.notifications),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Notifications",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _notificationService.markAllAsRead();
                    },
                    child: Text(
                      "Mark all as read",
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _notificationService.notificationsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final notifications = snapshot.data ?? [];

                  if (notifications.isEmpty) {
                    return Center(
                      child: Text(
                        "No notifications yet",
                        style: theme.textTheme.bodyLarge,
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      return _NotificationItem(
                        notification: n,
                        theme: theme,
                        onTap: () {
                          _handleNotificationTap(n);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> n) async {
    // 1. Mark as read
    if (n['is_read'] != true) {
      _notificationService.markAsRead(n['notification_id']);
    }

    // 2. Extract Data
    final String type = n['type'] ?? '';
    final String? actorId = n['actor_id'] ?? n['sender_id'];
    final String? actorName = n['actor_name'] ?? n['sender_name'] ?? 'User';
    final String? actorAvatar = n['actor_avatar'] ?? n['sender_avatar'];

    // Reference ID usually holds the target (Post ID, Comment ID, etc.)
    final String? referenceId =
        n['reference_id']?.toString() ?? n['post_id']?.toString();

    debugPrint(
      "🔔 Tapped Notification: Type=$type, Ref=$referenceId, Actor=$actorId",
    );

    // 3. Navigation Logic
    try {
      if (type == 'follow') {
        if (actorId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PublicProfileScreen(userId: actorId),
            ),
          );
        }
      } else if (type == 'like' || type == 'comment') {
        if (referenceId != null) {
          // Show loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );

          // Fetch Post
          final post = await FeedApi.fetchSinglePost(referenceId);

          // Hide loading
          if (mounted) Navigator.pop(context);

          if (post != null && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Post not found or deleted")),
            );
          }
        }
      } else if (type == 'message') {
        final conversationId = n['conversation_id']?.toString();

        if (conversationId != null && actorId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PersonalChatScreen(
                conversationId: conversationId,
                otherUser: {
                  'id': actorId,
                  'name': actorName,
                  'avatar': actorAvatar,
                  'headline': '', // Optional
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("❌ Navigation Error: $e");
      if (mounted) {
        // Ensure loading dialog is closed if error occurred
        // checking route stack might be complex, simplified check:
        // Navigator.pop(context); // Risky if dialog wasn't open
      }
    }
  }
}

class _NotificationItem extends StatelessWidget {
  final Map<String, dynamic> notification;
  final ThemeData theme;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.notification,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool unread = notification['is_read'] != true;
    final String type = notification['type'] ?? 'system';
    final String? avatarUrl =
        notification['actor_avatar'] ?? notification['senderAvatar'];

    // Icon Logic
    IconData icon = Icons.notifications;
    Color iconColor = theme.primaryColor;

    if (type == 'follow') {
      icon = Icons.person_add;
      iconColor = Colors.blue;
    } else if (type == 'like') {
      icon = Icons.favorite;
      iconColor = Colors.pink;
    } else if (type == 'comment') {
      icon = Icons.comment;
      iconColor = Colors.purple;
    } else if (type == 'message') {
      icon = Icons.message;
      iconColor = Colors.green;
    }

    return GestureDetector(
      onTap: onTap,
      // ... existing styling ...
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: unread
              ? theme.primaryColor.withOpacity(0.05)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: unread
                ? theme.primaryColor.withOpacity(0.2)
                : theme.dividerColor,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar or Icon
            if (avatarUrl != null && avatarUrl.isNotEmpty)
              CircleAvatar(backgroundImage: NetworkImage(avatarUrl), radius: 20)
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),

            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification['text'] ??
                        notification['title'] ??
                        "Notification",
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: unread ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  TimeAgoWidget(
                    dateTime:
                        DateTime.tryParse(
                          notification['created_at'] ??
                              notification['time'] ??
                              "",
                        ) ??
                        DateTime.now(),
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            if (unread)
              Container(
                margin: const EdgeInsets.only(left: 8, top: 8),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
