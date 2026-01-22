import 'package:flutter/material.dart';
import '../../widgets/app_top_bar.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                  Text("Recent", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {},
                    child: Text("Mark all as read", style: TextStyle(color: theme.primaryColor, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _NotificationItem(
                    title: "Sarah Chen liked your story",
                    subtitle: "Shared a new update in Feed",
                    time: "2m ago",
                    icon: Icons.favorite,
                    iconColor: Colors.pinkAccent,
                    unread: true,
                    theme: theme,
                  ),
                  _NotificationItem(
                    title: "Michael Torres commented on your post",
                    subtitle: "\"This design looks very clean and professional!\"",
                    time: "1h ago",
                    icon: Icons.chat_bubble,
                    iconColor: const Color(0xFFC084FC),
                    unread: true,
                    theme: theme,
                  ),
                  _NotificationItem(
                    title: "New job alert: Product Designer",
                    subtitle: "At TechM Practice and 5 other companies",
                    time: "3h ago",
                    icon: Icons.business_center,
                    iconColor: const Color(0xFF34D399),
                    unread: false,
                    theme: theme,
                  ),
                  _NotificationItem(
                    title: "Jessica Williams viewed your profile",
                    subtitle: "Found you via search results",
                    time: "5h ago",
                    icon: Icons.visibility,
                    iconColor: const Color(0xFFFACC15),
                    unread: false,
                    theme: theme,
                  ),
                  _NotificationItem(
                    title: "System Update",
                    subtitle: "New features have been added to your dashboard",
                    time: "1d ago",
                    icon: Icons.system_update,
                    iconColor: theme.primaryColor,
                    unread: false,
                    theme: theme,
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

class _NotificationItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color iconColor;
  final bool unread;
  final ThemeData theme;

  const _NotificationItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.unread,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unread ? theme.primaryColor.withValues(alpha: 0.05) : theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: unread ? theme.primaryColor.withValues(alpha: 0.2) : theme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (unread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: theme.primaryColor, shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(time, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
