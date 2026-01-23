import 'package:flutter/material.dart';
import 'package:cocpit_app/models/story_model.dart';
import 'package:cocpit_app/services/story_service.dart';
import 'package:cocpit_app/views/story/story_viewer_screen.dart';
import 'package:cocpit_app/views/story/create_story_screen.dart';

class StoryTray extends StatefulWidget {
  const StoryTray({super.key});

  @override
  State<StoryTray> createState() => _StoryTrayState();
}

class _StoryTrayState extends State<StoryTray> {
  List<StoryGroup> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStories();
  }

  Future<void> _fetchStories() async {
    try {
      final groups = await StoryService.getGroupedStories();
      if (mounted) {
        setState(() {
          _groups = _sortGroups(groups);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching stories: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<StoryGroup> _sortGroups(List<StoryGroup> groups) {
    // 1. Separate Current User
    List<StoryGroup> sorted = [];
    StoryGroup? currentUserGroup;

    // Find current user group (or create empty one if needed? Service handles it usually)
    // The service returns groups including current user if they exist or if backend creates a shell.
    // The prompt backend code:
    // "Initialize Current User Group always... if (currentUser) groupsMap.set..."
    // So current user is always present.

    final currentUserIndex = groups.indexWhere((g) => g.isCurrentUser);
    if (currentUserIndex != -1) {
      currentUserGroup = groups.removeAt(currentUserIndex);
    }

    // 2. Sort others: Unseen first, then Seen. Both by latestStoryAt desc.
    groups.sort((a, b) {
      bool aUnseen = a.stories.any((s) => !s.hasViewed);
      bool bUnseen = b.stories.any((s) => !s.hasViewed);

      if (aUnseen && !bUnseen) return -1;
      if (!aUnseen && bUnseen) return 1;

      // Both unseen or both seen -> sort by time
      // latestStoryAt is string, needs parsing
      DateTime? aTime = a.latestStoryAt != null ? DateTime.tryParse(a.latestStoryAt!) : null;
      DateTime? bTime = b.latestStoryAt != null ? DateTime.tryParse(b.latestStoryAt!) : null;

      if (aTime != null && bTime != null) {
         return bTime.compareTo(aTime);
      }
      return 0;
    });

    if (currentUserGroup != null) {
      sorted.add(currentUserGroup);
    }
    sorted.addAll(groups);

    return sorted;
  }

  Future<void> _handleRefresh() async {
    setState(() => _isLoading = true);
    await _fetchStories();
  }

  void _onStoryViewed() {
    // When returning from viewer, refresh logic (sorting might change)
    _fetchStories();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 110,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          return _buildStoryItem(group, index);
        },
      ),
    );
  }

  Widget _buildStoryItem(StoryGroup group, int index) {
    final hasStories = group.stories.isNotEmpty;
    final hasUnseen = group.stories.any((s) => !s.hasViewed);
    final theme = Theme.of(context);

    // Border Color
    Color borderColor = Colors.grey;
    if (hasStories) {
      if (hasUnseen) {
        borderColor = theme.primaryColor; // Green/Blue
      } else {
        borderColor = Colors.grey;
      }
    } else {
       // No stories (Current User usually)
       borderColor = Colors.transparent;
    }

    return GestureDetector(
      onTap: () async {
        if (group.isCurrentUser) {
           if (!hasStories) {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateStoryScreen())
              );
              if (res == true) _handleRefresh();
           } else {
              // Show option to view or add
              showModalBottomSheet(context: context, builder: (c) {
                 return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       ListTile(
                          leading: const Icon(Icons.visibility),
                          title: const Text("View Story"),
                          onTap: () {
                             Navigator.pop(c);
                             _openViewer(index);
                          },
                       ),
                       ListTile(
                          leading: const Icon(Icons.add),
                          title: const Text("Add to Story"),
                          onTap: () async {
                             Navigator.pop(c);
                             final res = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CreateStoryScreen())
                             );
                             if (res == true) _handleRefresh();
                          },
                       ),
                    ],
                 );
              });
           }
        } else {
           if (hasStories) _openViewer(index);
        }
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: hasStories ? Border.all(color: borderColor, width: 3) : null,
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: group.author.avatar != null
                        ? NetworkImage(group.author.avatar!)
                        : null,
                    child: group.author.avatar == null
                        ? Text(group.author.name[0].toUpperCase())
                        : null,
                  ),
                ),
                if (group.isCurrentUser && !hasStories)
                   Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                         padding: const EdgeInsets.all(4),
                         decoration: BoxDecoration(
                            color: theme.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                         ),
                         child: const Icon(Icons.add, size: 16, color: Colors.white),
                      ),
                   ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
               group.isCurrentUser ? "You" : group.author.name.split(' ')[0], // First name
               style: theme.textTheme.bodySmall,
               overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _openViewer(int index) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryViewerScreen(
          groups: _groups,
          initialGroupIndex: index,
        ),
      ),
    );
    _onStoryViewed();
  }
}
