import 'package:flutter/material.dart';
import '../../widgets/app_top_bar.dart';
import '../../services/notification_service.dart';
import '../../widgets/time_ago_widget.dart';

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
                initialData: _notificationService.currentNotifications,
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
    if (!mounted) return;
    await NotificationService.navigateToNotificationTarget(context, n);
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
    } else if (type == 'share') {
      icon = Icons.share;
      iconColor = Colors.orange;
    } else if (type == 'message' || type == 'chat') {
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
            // Avatar or Icon (Target: Profile)
            GestureDetector(
              onTap: () {
                final actorId =
                    (notification['actor_id'] ?? notification['sender_id'])
                        ?.toString();
                if (actorId != null) {
                  NotificationService.navigateToNotificationTarget(context, {
                    'type': 'follow',
                    'actor_id': actorId,
                  });
                }
              },
              child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(avatarUrl),
                      radius: 20,
                    )
                  : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
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
