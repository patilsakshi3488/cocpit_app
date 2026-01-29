import 'package:flutter/material.dart';
import '../views/feed/chat_screen.dart';
import '../views/feed/notification_screen.dart';
import '../services/notification_service.dart';

enum SearchType { feed, jobs, events, chat, notifications }

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final SearchType searchType;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSearchTap;
  final LayerLink? layerLink;
  final VoidCallback? onFilterTap;

  const AppTopBar({
    super.key,
    required this.searchType,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSearchTap,
    this.layerLink,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    String hintText;
    switch (searchType) {
      case SearchType.feed:
        hintText = "Search posts / people";
        break;
      case SearchType.jobs:
        hintText = "Search jobs";
        break;
      case SearchType.events:
        hintText = "Search events";
        break;
      case SearchType.chat:
        hintText = "Search conversations";
        break;
      case SearchType.notifications:
        hintText = "Search notifications";
        break;
    }

    Widget searchField = Container(
      height: 44,
      padding: const EdgeInsets.only(left: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: theme.textTheme.bodySmall?.color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              onTap: onSearchTap,
              readOnly: onSearchTap != null,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
                border: InputBorder.none,
                isDense: true,
                suffixIcon: onFilterTap != null
                    ? IconButton(
                        icon: const Icon(Icons.tune, size: 20),
                        onPressed: onFilterTap,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );

    if (layerLink != null) {
      searchField = CompositedTransformTarget(
        link: layerLink!,
        child: searchField,
      );
    }

    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      toolbarHeight: 70,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            if (canPop)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
                onPressed: () => Navigator.pop(context),
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.logo_dev,
                  color: theme.primaryColor,
                  size: 24,
                ),
              ),
            const SizedBox(width: 12),
            if (searchType == SearchType.notifications)
              Expanded(
                child: Text(
                  "Notifications",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Expanded(child: searchField),
            const SizedBox(width: 8),
            if (searchType != SearchType.notifications)
              StreamBuilder<int>(
                stream: NotificationService().unreadCountStream,
                initialData: NotificationService().unreadCount,
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Stack(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.notifications_none,
                          color: theme.iconTheme.color,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationScreen(),
                            ),
                          );
                        },
                      ),
                      if (count > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            if (searchType != SearchType.chat &&
                searchType != SearchType.notifications)
              IconButton(
                icon: Icon(
                  Icons.chat_bubble_outline,
                  color: theme.iconTheme.color,
                ),
                onPressed: () {
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).push(MaterialPageRoute(builder: (_) => const ChatScreen()));
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}
