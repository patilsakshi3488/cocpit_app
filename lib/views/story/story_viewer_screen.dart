import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cocpit_app/models/story_model.dart';
import 'package:cocpit_app/services/story_service.dart';
import 'package:cocpit_app/views/story/story_comments_sheet.dart';
import 'package:cocpit_app/views/profile/public_profile_screen.dart';
import 'package:cocpit_app/views/feed/post_detail_screen.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<StoryGroup> groups;
  final int initialGroupIndex;
  final String? initialStoryId;
  final bool autoShowComments;
  final bool autoShowLikes;

  const StoryViewerScreen({
    super.key,
    required this.groups,
    required this.initialGroupIndex,
    this.initialStoryId,
    this.autoShowComments = false,
    this.autoShowLikes = false,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  // State
  late int _currentGroupIndex;
  late int _currentStoryIndex;

  // Media Controllers
  VideoPlayerController? _videoController;
  late AnimationController _animController;

  // Logic
  bool _isPaused = false;
  double _dragOffsetY = 0.0;

  // -------------------------
  // CACHE (Single Source of Truth)
  // -------------------------
  final Map<String, Map<String, dynamic>> _engagementCache = {};

  int _likeCount(String storyId) =>
      _engagementCache[storyId]?['likeCount'] ?? 0;

  int _viewCount(String storyId) =>
      _engagementCache[storyId]?['viewCount'] ?? 0;

  int _commentCount(String storyId) =>
      _engagementCache[storyId]?['commentCount'] ?? 0;

  bool _hasLiked(String storyId) =>
      _engagementCache[storyId]?['hasLiked'] ?? false;

  @override
  void initState() {
    super.initState();
    _currentGroupIndex = widget.initialGroupIndex;

    // Initial bounds check
    if (_currentGroupIndex < 0 || _currentGroupIndex >= widget.groups.length) {
      _currentGroupIndex = 0;
    }

    // Determine starting story
    if (widget.groups.isNotEmpty) {
      final group = widget.groups[_currentGroupIndex];
      int targetIndex = -1;

      // 1. Try to find specific story if ID provided
      if (widget.initialStoryId != null) {
        targetIndex = group.stories.indexWhere(
          (s) => s.storyId == widget.initialStoryId,
        );
      }

      // 2. Fallback to first unseen
      if (targetIndex == -1) {
        targetIndex = group.stories.indexWhere((s) => !s.hasViewed);
      }

      // 3. Fallback to 0
      _currentStoryIndex = targetIndex != -1 ? targetIndex : 0;
    } else {
      _currentStoryIndex = 0;
    }

    _animController = AnimationController(vsync: this);
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onStoryFinished();
      }
    });

    _loadStory();

    // Auto-open comments checking
    if (widget.autoShowComments) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showComments();
      });
    } else if (widget.autoShowLikes) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showLikes();
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _animController.dispose();
    super.dispose();
  }

  // Safe Getters
  StoryGroup? get _currentGroupSafe {
    if (widget.groups.isEmpty) return null;
    if (_currentGroupIndex >= widget.groups.length) return null;
    return widget.groups[_currentGroupIndex];
  }

  Story? get _currentStorySafe {
    final group = _currentGroupSafe;
    if (group == null) return null;
    if (group.stories.isEmpty) return null;
    if (_currentStoryIndex >= group.stories.length) return null;
    return group.stories[_currentStoryIndex];
  }

  Future<void> _loadStory() async {
    _videoController?.dispose();
    _videoController = null;
    _animController.stop();
    _animController.reset();

    final story = _currentStorySafe;
    if (story == null) return; // Safety check

    // Mark as viewed in API
    if (!story.isAuthor && !story.hasViewed) {
      StoryService.viewStory(story.storyId);
      setState(() {
        story.hasViewed = true;
      });
    }

    // 🔥 FETCH LATEST COUNTS to CACHE
    _fetchEngagement(story.storyId);

    if (story.mediaType == 'video') {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(story.mediaUrl),
      );
      try {
        await _videoController!.initialize();
        if (!mounted) return;
        setState(() {}); // Rebuild to show video

        final duration = _videoController!.value.duration;
        _animController.duration = duration;

        _videoController!.play();
        _animController.forward();
      } catch (e) {
        print("Error loading video: $e");
        _onStoryFinished(); // Skip if error
      }
    } else {
      _animController.duration = const Duration(seconds: 5);
      // Start animation immediately
      _animController.forward();
      // Optionally warm cache (no dependency)
      precacheImage(NetworkImage(story.mediaUrl), context);
    }
  }

  Future<void> _fetchEngagement(String storyId) async {
    try {
      final details = await StoryService.getStoryDetails(storyId);

      if (!mounted) return;

      _engagementCache[storyId] = {
        "viewCount": details['view_count'] ?? 0,
        "likeCount": details['like_count'] ?? 0,
        "commentCount": details['comment_count'] ?? 0,
        "hasLiked": details['has_liked'] ?? false,
        "likes": details['likes'] ?? details['reporters'] ?? [], // fallback
        "viewers": details['viewers'] ?? [],
      };

      setState(() {}); // Force rebuild with new cache
    } catch (_) {
      // If fail, we rely on old data or 0
    }
  }

  // Method to navigate to profile
  void _navigateToProfile() {
    _pause();
    final group = _currentGroupSafe;
    if (group == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(userId: group.author.id),
      ),
    ).then((_) => _resume());
  }

  void _onStoryFinished() {
    final group = _currentGroupSafe;
    if (group == null) {
      Navigator.pop(context);
      return;
    }

    if (_currentStoryIndex < group.stories.length - 1) {
      setState(() {
        _currentStoryIndex++;
      });
      _loadStory();
    } else {
      // Group finished. Find next group with unseen stories that is not current user.
      int nextGroupIndex = -1;

      for (int i = _currentGroupIndex + 1; i < widget.groups.length; i++) {
        final g = widget.groups[i];
        if (!g.isCurrentUser && g.stories.any((s) => !s.hasViewed)) {
          nextGroupIndex = i;
          break;
        }
      }

      if (nextGroupIndex != -1) {
        // Found next group
        final g = widget.groups[nextGroupIndex];
        int firstUnseen = g.stories.indexWhere((s) => !s.hasViewed);

        setState(() {
          _currentGroupIndex = nextGroupIndex;
          _currentStoryIndex = firstUnseen != -1 ? firstUnseen : 0;
          _dragOffsetY = 0.0; // Reset drag just in case
        });
        _loadStory();
      } else {
        Navigator.pop(context);
      }
    }
  }

  void _previousStory() {
    // 1️⃣ Previous story in same user
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
      });
      _loadStory();
      return;
    }

    // 2️⃣ Find previous NON-current-user group
    int prevGroupIndex = _currentGroupIndex - 1;

    while (prevGroupIndex >= 0 && widget.groups[prevGroupIndex].isCurrentUser) {
      prevGroupIndex--; // ⏭ skip current user
    }

    if (prevGroupIndex >= 0) {
      final prevGroup = widget.groups[prevGroupIndex];

      // Find first unseen story
      final firstUnseenIndex = prevGroup.stories.indexWhere(
        (s) => !s.hasViewed,
      );

      setState(() {
        _currentGroupIndex = prevGroupIndex;

        if (firstUnseenIndex != -1) {
          _currentStoryIndex = firstUnseenIndex;
        } else {
          _currentStoryIndex = prevGroup.stories.length - 1;
        }
      });

      _loadStory();
      return;
    }
  }

  /// STRICT PAUSE: Ensures everything stops immediately
  void _pause() {
    // Force pause even if _isPaused is true, to be safe
    setState(() => _isPaused = true);
    _animController.stop();
    _videoController?.pause();
  }

  void _resume() {
    if (!_isPaused) return; // Only resume if effectively paused by our logic
    setState(() => _isPaused = false);
    _animController.forward();
    _videoController?.play();
  }

  Future<void> _handleReaction() async {
    final story = _currentStorySafe;
    if (story == null) return;

    final id = story.storyId;

    // Init cache if missing (edge case)
    if (!_engagementCache.containsKey(id)) {
      _engagementCache[id] = {
        "viewCount": story.viewCount,
        "likeCount": story.likeCount,
        "commentCount": story.commentCount,
        "hasLiked": story.hasLiked,
        "likes": [],
        "viewers": [],
      };
    }

    final cached = _engagementCache[id]!;
    final wasLiked = cached['hasLiked'] as bool;

    // Optimistic Update
    setState(() {
      cached['hasLiked'] = !wasLiked;
      cached['likeCount'] = (cached['likeCount'] as int) + (wasLiked ? -1 : 1);
    });

    try {
      // Toggle string 'true' usually means "like"
      final isLikedResponse = await StoryService.reactToStory(id, 'true');

      // Re-fetch truth to be safe
      await _fetchEngagement(id);
    } catch (e) {
      // Rollback
      if (mounted) {
        setState(() {
          cached['hasLiked'] = wasLiked;
          cached['likeCount'] =
              (cached['likeCount'] as int) + (wasLiked ? 1 : -1);
        });
      }
    }
  }

  Future<void> _deleteStory() async {
    _pause();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Delete Story?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final story = _currentStorySafe;
      final group = _currentGroupSafe;

      if (story == null || group == null) return;

      try {
        await StoryService.deleteStory(story.storyId);
        // Remove locally
        setState(() {
          group.stories.removeAt(_currentStoryIndex);

          if (group.stories.isEmpty) {
            Navigator.pop(context); // Close if no stories left
            return;
          }

          if (_currentStoryIndex >= group.stories.length) {
            _currentStoryIndex = group.stories.length - 1;
          }
        });

        if (mounted) {
          _loadStory(); // Load new current
        }
        return; // Don't resume
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed: $e")));
      }
    }
    _resume();
  }

  void _showViewers() async {
    _pause();
    final story = _currentStorySafe;
    if (story == null) return;

    try {
      final details = await StoryService.getStoryDetails(story.storyId);
      if (!mounted) return;

      await showModalBottomSheet(
        context: context,
        builder: (c) => _UserListSheet(
          title: "Viewers",
          users: details['viewers'] as List? ?? [],
        ),
        backgroundColor: Colors.transparent,
      );
    } catch (e) {
      // ignore
    }
    _resume();
  }

  void _showLikes() async {
    _pause();
    final story = _currentStorySafe;
    if (story == null) return;

    try {
      final details = await StoryService.getStoryDetails(story.storyId);
      if (!mounted) return;

      // Assuming details contains 'likes' array based on standard pattern
      // If not, it will just show empty, but won't crash
      final likes =
          details['likes'] as List? ?? details['reporters'] as List? ?? [];

      await showModalBottomSheet(
        context: context,
        builder: (c) => _UserListSheet(title: "Likes", users: likes),
        backgroundColor: Colors.transparent,
      );
    } catch (e) {
      // ignore
    }
    _resume();
  }

  void _showComments() {
    _pause();
    final story = _currentStorySafe;
    if (story == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StoryCommentsSheet(
        storyId: story.storyId,
        initialCount: story.commentCount,
        isStoryAuthor: story.isAuthor,
        onCommentCountChanged: (newCount) {
          setState(() => story.commentCount = newCount);
        },
      ),
    ).then((_) => _resume());
  }

  bool _isLongText(String text) {
    return text.length > 80;
  }

  Future<void> _openLinkedPostFromMetadata(dynamic postId) async {
    if (postId == null) return;
    _pause();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(
          post: {
            "id": postId.toString(),
            "author": {"name": "Loading...", "id": ""},
          },
        ),
      ),
    ).then((_) => _resume());
  }

  Future<void> _openLinkedPost(String rawTitle) async {
    final postId = rawTitle.replaceFirst("LINKED_POST:", "");
    if (postId.isEmpty) return;
    _openLinkedPostFromMetadata(postId);
  }

  Future<void> _showDescriptionSheet(
    BuildContext context,
    String description,
  ) async {
    _pause();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black45, // tap outside to close
      builder: (_) {
        return GestureDetector(
          onTap: () {}, // prevent sheet close on inner tap
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    _resume();
  }

  void _showMoreOptions(Story story) {
    _pause();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Wrap(
            children: [
              if (story.isAuthor)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    "Delete Story",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(c);
                    _deleteStory();
                  },
                ),
            ],
          ),
        ),
      ),
    ).then((_) => _resume());
  }

  @override
  Widget build(BuildContext context) {
    final group = _currentGroupSafe;
    final story = _currentStorySafe;

    if (group == null || story == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black, // Dark background for better swipe effect
      body: Transform.translate(
        offset: Offset(0, _dragOffsetY),
        child: GestureDetector(
          onTapDown: (_) => _pause(),
          onTapUp: (details) {
            _resume();
            final width = MediaQuery.of(context).size.width;
            final dx = details.globalPosition.dx;

            if (dx < width * 0.25) {
              _previousStory();
            } else if (dx > width * 0.75) {
              _onStoryFinished();
            } else {
              // Center Tap: Check metadata for link
              if (story.storyMetadata != null &&
                  story.storyMetadata!['linked_post_id'] != null) {
                _openLinkedPostFromMetadata(
                  story.storyMetadata!['linked_post_id'],
                );
              } else if (story.title != null &&
                  story.title!.startsWith("LINKED_POST:")) {
                // BACKWARD COMPATIBILITY
                _openLinkedPost(story.title!);
              } else {
                _onStoryFinished(); // Default
              }
            }
          },
          onTapCancel: _resume,
          onLongPress: _pause,
          onLongPressUp: _resume,
          onVerticalDragUpdate: (details) {
            // Drag Down -> Close
            if (details.delta.dy > 0 || _dragOffsetY > 0) {
              setState(() {
                _dragOffsetY += details.delta.dy;
              });
            }
          },
          onVerticalDragEnd: (details) {
            if (_dragOffsetY > 100 ||
                (details.primaryVelocity != null &&
                    details.primaryVelocity! > 500)) {
              Navigator.pop(context);
            } else if (details.primaryVelocity != null &&
                details.primaryVelocity! < -500) {
              // Swipe Up detected
              if (_dragOffsetY == 0) {
                if (story.isAuthor) {
                  _showViewers();
                } else if (story.description != null &&
                    story.description!.isNotEmpty) {
                  _showDescriptionSheet(context, story.description!);
                }
              }
              setState(() {
                _dragOffsetY = 0.0;
              });
            } else {
              setState(() {
                _dragOffsetY = 0.0;
              });
            }
          },
          child: Container(
            color: colorScheme.surface, // Inner content bg
            child: Stack(
              children: [
                // ======================
                // Media
                // ======================
                Positioned.fill(child: _buildMedia(story)),

                // ======================
                // Tap Zones (REMOVED - Handled by Parent)
                // ======================

                // ======================
                // Top Overlay
                // ======================
                SafeArea(
                  child: Column(
                    children: [
                      // Progress Bars
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        child: Row(
                          children: List.generate(
                            group.stories.length,
                            (index) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: _buildProgressBar(index, context),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _navigateToProfile,
                              child: CircleAvatar(
                                backgroundImage: group.author.avatar != null
                                    ? NetworkImage(group.author.avatar!)
                                    : null,
                                backgroundColor: colorScheme.surfaceVariant,
                                child: group.author.avatar == null
                                    ? Text(
                                        group.author.name[0],
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _navigateToProfile,
                              child: Text(
                                group.author.name,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _timeAgo(story.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const Spacer(),

                            // 3-Dot Menu for Author
                            if (story.isAuthor)
                              IconButton(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: colorScheme.onSurface,
                                ),
                                onPressed: () => _showMoreOptions(story),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ======================
                // Footer Overlay
                // ======================
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // SHOW DESCRIPTION (With Opaque HitTest to prevent drill-through)
                      if (story.description != null &&
                          story.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: GestureDetector(
                            behavior: HitTestBehavior
                                .opaque, // Blocks tap from going to parent
                            onTap: () {
                              if (_isLongText(story.description!)) {
                                _showDescriptionSheet(
                                  context,
                                  story.description!,
                                );
                              }
                            },
                            child: Column(
                              children: [
                                Text(
                                  story.description!,
                                  textAlign: TextAlign.center,
                                  maxLines: _isLongText(story.description!)
                                      ? 2
                                      : 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: Colors.white,
                                    shadows: [
                                      const Shadow(
                                        blurRadius: 4,
                                        color: Colors.black54,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),

                                // READ MORE (tap only here)
                                if (_isLongText(story.description!))
                                  GestureDetector(
                                    onTap: () {
                                      _showDescriptionSheet(
                                        context,
                                        story.description!,
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black45,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          "Read more",
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                      _buildFooterActions(story, context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedia(Story story) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (story.mediaType == 'video') {
          if (_videoController != null &&
              _videoController!.value.isInitialized) {
            final videoSize = _videoController!.value.size;
            final aspectRatio = videoSize.width / videoSize.height;

            return Center(
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        } else {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight,
                maxWidth: constraints.maxWidth,
              ),
              child: Image.network(
                story.mediaUrl,
                fit: BoxFit.contain,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildProgressBar(int index, BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: AnimatedBuilder(
        animation: _animController,
        builder: (_, __) {
          double value;

          if (index < _currentStoryIndex) {
            value = 1.0;
          } else if (index == _currentStoryIndex) {
            value = _animController.value;
          } else {
            value = 0.0;
          }

          return LinearProgressIndicator(
            value: value,
            backgroundColor: colorScheme.onSurface.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onSurface),
          );
        },
      ),
    );
  }

  Widget _buildFooterActions(Story story, BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (story.isAuthor) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Viewers
          TextButton.icon(
            onPressed: _showViewers,
            icon: Icon(Icons.visibility, color: colorScheme.onSurface),
            label: Text(
              "${_viewCount(story.storyId)}",
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ),

          // Comments
          IconButton(
            onPressed: _showComments,
            icon: Icon(Icons.chat_bubble_outline, color: colorScheme.onSurface),
            tooltip: "Comments",
          ),

          // Likes (Always visible for author to check who liked)
          GestureDetector(
            onTap: _showLikes,
            child: Row(
              children: [
                Icon(Icons.favorite, color: Colors.white, size: 24),
                const SizedBox(width: 4),
                Text(
                  '${_likeCount(story.storyId)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Comment Button
          GestureDetector(
            onTap: _showComments,
            child: Container(
              // larger hit area
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: colorScheme.onSurface,
                    size: 28,
                  ),
                  if (_commentCount(story.storyId) > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      "${_commentCount(story.storyId)}",
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(width: 12), // Spacing
          // Like Button
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _hasLiked(story.storyId)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: _hasLiked(story.storyId)
                        ? colorScheme.error
                        : colorScheme.onSurface,
                    size: 30,
                  ),
                  onPressed: _handleReaction,
                ),
                // Show count for viewers too if > 0
                if (_likeCount(story.storyId) > 0)
                  Text(
                    "${_likeCount(story.storyId)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }
  }

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 0) return "${diff.inDays}d";
    if (diff.inHours > 0) return "${diff.inHours}h";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m";
    return "Just now";
  }
}

// Reusable sheet for Viewers/Likes
class _UserListSheet extends StatelessWidget {
  final String title;
  final List<dynamic> users;

  const _UserListSheet({required this.title, required this.users});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Dark sheet
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "$title (${users.length})",
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (users.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  "No $title yet",
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final v = users[index];
                  // Robust parsing
                  final userObj = v is Map ? (v['user'] ?? v) : {};

                  final name =
                      userObj['name'] ??
                      userObj['full_name'] ??
                      userObj['user_name'] ??
                      userObj['username'] ??
                      "User";

                  final avatar =
                      userObj['avatar'] ??
                      userObj['avatar_url'] ??
                      userObj['profile_picture'] ??
                      userObj['user_avatar'];

                  final userId =
                      userObj['id']?.toString() ?? userObj['_id']?.toString();

                  return GestureDetector(
                    onTap: userId != null
                        ? () {
                            // Navigate to profile
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PublicProfileScreen(userId: userId),
                              ),
                            );
                          }
                        : null,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundImage: avatar != null
                            ? NetworkImage(avatar)
                            : null,
                        backgroundColor: Colors.white10,
                        child: avatar == null
                            ? const Icon(Icons.person, color: Colors.white70)
                            : null,
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
