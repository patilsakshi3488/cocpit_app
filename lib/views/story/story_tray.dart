import 'package:flutter/material.dart';
import 'package:cocpit_app/models/story_model.dart';
import 'package:cocpit_app/services/story_service.dart';
import 'package:cocpit_app/views/story/story_viewer_screen.dart';
import 'package:cocpit_app/views/story/create_story_screen.dart';
import 'package:cocpit_app/views/story/video_story_thumbnail.dart';

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
    if (mounted) {
      setState(() {
        _groups = _sortGroups(_groups);
      });
    }
    _fetchStories();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    double itemWidth = MediaQuery.of(context).size.width > 600 ? 150 : 120;

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          return _buildStoryItem(group, index, itemWidth, theme, colorScheme);
        },
      ),
    );
  }

  Widget _buildStoryItem(
      StoryGroup group,
      int index,
      double width,
      ThemeData theme,
      ColorScheme colorScheme,
      ) {
    final hasStories = group.stories.isNotEmpty;

    String? bgImage;
    String? videoUrl;
    if (hasStories) {
      final latest = group.stories.last;
      if (latest.mediaType == 'image') {
        bgImage = latest.mediaUrl;
      } else if (latest.mediaType == 'video') {
        videoUrl = latest.mediaUrl;
      }
    }

    // Border logic
    final bool hasUnseen = group.stories.any((s) => !s.hasViewed);
    final Border? border = hasStories
        ? Border.all(
            color: hasUnseen
                ? colorScheme.primary
                : (Colors.grey[400] ?? Colors.grey),
            width: hasUnseen ? 3.0 : 2.0,
          )
        : null;

    return GestureDetector(
      onTap: () async {
        if (group.isCurrentUser) {
          if (!hasStories) {
            final res = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
            );
            if (res == true) _handleRefresh();
          } else {
            _openViewer(index);
          }
        } else {
          if (hasStories) _openViewer(index);
        }
      },
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 12),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: border,
          image: bgImage != null
              ? DecorationImage(
                  image: NetworkImage(bgImage),
                  fit: BoxFit.cover,
                )
              : null,
          color: (group.isCurrentUser && !hasStories)
              ? colorScheme.primary
              : colorScheme.surfaceVariant,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video Thumbnail Layer
            if (videoUrl != null && bgImage == null)
              Positioned.fill(
                child: VideoStoryThumbnail(mediaUrl: videoUrl),
              ),
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
                        color: colorScheme.onPrimary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        color: colorScheme.onPrimary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Your Story",
                      style: TextStyle(
                        color: colorScheme.onPrimary,
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
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: colorScheme.primary,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundImage: group.author.avatar != null
                            ? NetworkImage(group.author.avatar!)
                            : null,
                        child: group.author.avatar == null
                            ? Text(
                          group.author.name[0],
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                          ),
                        )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "You",
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(color: Colors.black38, blurRadius: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // + Icon
              Positioned(
                top: 6,
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
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      color: colorScheme.onSurface,
                      size: 20,
                    ),
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
                      backgroundColor: colorScheme.primary,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundImage: group.author.avatar != null
                            ? NetworkImage(group.author.avatar!)
                            : null,
                        child: group.author.avatar == null
                            ? Text(
                          group.author.name[0],
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                          ),
                        )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      group.author.name,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(color: Colors.black38, blurRadius: 4),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
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


