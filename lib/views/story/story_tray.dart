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
      DateTime? aTime = a.latestStoryAt != null
          ? DateTime.tryParse(a.latestStoryAt!)
          : null;
      DateTime? bTime = b.latestStoryAt != null
          ? DateTime.tryParse(b.latestStoryAt!)
          : null;

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
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    double itemWidth = MediaQuery.of(context).size.width > 600 ? 150 : 120;

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          return _buildStoryItem(group, index, itemWidth, theme);
        },
      ),
    );
  }

  Widget _buildStoryItem(
      StoryGroup group, int index, double width, ThemeData theme) {
    final hasStories = group.stories.isNotEmpty;
    // For background image: if video, fallback to avatar or generic
    String? bgImage;
    if (hasStories) {
      // Find latest story or first? usually latest for preview
      final latest = group.stories.last;
      if (latest.mediaType == 'image') {
        bgImage = latest.mediaUrl;
      }
    }

    return GestureDetector(
      onTap: () async {
        if (group.isCurrentUser) {
          if (!hasStories) {
            // No story -> Create
            final res = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
            );
            if (res == true) _handleRefresh();
          } else {
            // Has story -> View
            _openViewer(index);
          }
        } else {
          // Other user -> View
          if (hasStories) _openViewer(index);
        }
      },
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: bgImage != null
              ? DecorationImage(
                  image: NetworkImage(bgImage),
                  fit: BoxFit.cover,
                )
              : null,
          color: (group.isCurrentUser && !hasStories)
              ? theme.primaryColor
              : theme.cardColor,
        ),
        child: Stack(
          children: [
            // ======================
            // 1. Current User - No Story
            // ======================
            if (group.isCurrentUser && !hasStories)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onPrimary.withValues(
                          alpha: 0.2,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        color: theme.colorScheme.onPrimary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Your Update",
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

            // ======================
            // 2. Current User - Has Story
            // ======================
            if (group.isCurrentUser && hasStories) ...[
               // Optional: Show "Your Story" text or just clean view?
               // Requirement: "like other users" but with + icon.
               // Other users show Avatar + Name.
               // So for me, show My Avatar + "You" (or Name)
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.primaryColor,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundImage: group.author.avatar != null
                            ? NetworkImage(group.author.avatar!)
                            : null,
                        child: group.author.avatar == null
                           ? Text(group.author.name[0]) : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "You",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                    ),
                  ],
                ),
              ),

              // + Icon for creating NEW story
              Positioned(
                bottom: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () async {
                     final res = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
                     );
                     if (res == true) _handleRefresh();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],

            // ======================
            // 3. Other Users
            // ======================
            if (!group.isCurrentUser)
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.primaryColor,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundImage: group.author.avatar != null
                            ? NetworkImage(group.author.avatar!)
                            : null,
                        child: group.author.avatar == null
                            ? Text(group.author.name[0])
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      group.author.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

            // If No BG image (e.g. video only), maybe show some icon or gradient
            if (bgImage == null && hasStories)
               Center(
                  child: Icon(Icons.play_circle_fill, color: Colors.white.withOpacity(0.8), size: 40),
               )
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
