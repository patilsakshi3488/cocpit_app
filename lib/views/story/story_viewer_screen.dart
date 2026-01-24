import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cocpit_app/models/story_model.dart';
import 'package:cocpit_app/services/story_service.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<StoryGroup> groups;
  final int initialGroupIndex;

  const StoryViewerScreen({
    super.key,
    required this.groups,
    required this.initialGroupIndex,
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

  @override
  void initState() {
    super.initState();
    _currentGroupIndex = widget.initialGroupIndex;

    // Find first unseen story
    final group = widget.groups[_currentGroupIndex];
    int firstUnseen = group.stories.indexWhere((s) => !s.hasViewed);
    _currentStoryIndex = firstUnseen != -1 ? firstUnseen : 0;

    _animController = AnimationController(vsync: this);
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onStoryFinished();
      }
    });

    _loadStory();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _animController.dispose();
    super.dispose();
  }

  StoryGroup get _currentGroup => widget.groups[_currentGroupIndex];
  Story get _currentStory => _currentGroup.stories[_currentStoryIndex];

  Future<void> _loadStory() async {
    _videoController?.dispose();
    _videoController = null;
    _animController.stop();
    _animController.reset();

    final story = _currentStory;

    // Mark as viewed in API
    if (!story.isAuthor && !story.hasViewed) {
      StoryService.viewStory(story.storyId);
      setState(() {
        story.hasViewed = true;
      });
    }

    if (story.mediaType == 'video') {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(story.mediaUrl));
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

  void _onStoryFinished() {
    if (_currentStoryIndex < _currentGroup.stories.length - 1) {
      setState(() {
        _currentStoryIndex++;
      });
      _loadStory();
    } else {
      // Group finished
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
      });
      _loadStory();
    } else {
      // Start of group, maybe restart or close?
      // Usually restarts the first story or stays there.
      _loadStory();
    }
  }

  void _pause() {
    if (_isPaused) return;
    setState(() => _isPaused = true);
    _animController.stop();
    _videoController?.pause();
  }

  void _resume() {
    if (!_isPaused) return;
    setState(() => _isPaused = false);
    _animController.forward();
    _videoController?.play();
  }

  Future<void> _handleReaction() async {
    // Optimistic toggle
    final story = _currentStory;
    final wasLiked = story.hasLiked;
    final oldLikeCount = story.likeCount;

    setState(() {
      story.hasLiked = !wasLiked;
      story.likeCount = wasLiked ? oldLikeCount - 1 : oldLikeCount + 1;
    });

    try {
      final isLiked = await StoryService.reactToStory(story.storyId, 'true');
      // Update with actual server state if needed, but optimistic is usually fine.
      if (mounted) {
        setState(() {
          story.hasLiked = isLiked;
          // Adjust count if mismatch? simplified for now.
        });
      }
    } catch (e) {
      // Revert
      if (mounted) {
        setState(() {
          story.hasLiked = wasLiked;
          story.likeCount = oldLikeCount;
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
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Delete")),
          ],
        )
    );

    if (confirm == true) {
      try {
        await StoryService.deleteStory(_currentStory.storyId);
        // Remove locally
        setState(() {
          _currentGroup.stories.removeAt(_currentStoryIndex);
        });

        if (_currentGroup.stories.isEmpty) {
          Navigator.pop(context); // Close if no stories left
        } else {
          if (_currentStoryIndex >= _currentGroup.stories.length) {
            _currentStoryIndex--;
          }
          _loadStory(); // Load new current
        }
        return; // Don't resume
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
      }
    }
    _resume();
  }

  void _showViewers() async {
    _pause();
    try {
      final details = await StoryService.getStoryDetails(_currentStory.storyId);
      if (!mounted) return;

      await showModalBottomSheet(
        context: context,
        builder: (c) => _ViewersSheet(details: details),
        backgroundColor: Colors.transparent,
      );
    } catch (e) {
      // ignore
    }
    _resume();
  }

  bool _isLongText(String text) {
    return text.length > 80; // tweak if needed
  }

  Future<void> _showDescriptionSheet(
      BuildContext context,
      // String title,
      String description,
      ) async {
    _pause(); // ⏸ pause story

    debugPrint("clicked on description bar");
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
              maxHeight: MediaQuery.of(context).size.height * 0.2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
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

                // if (title.isNotEmpty)
                //   Text(
                //     title,
                //     style: theme.textTheme.titleMedium?.copyWith(
                //       fontWeight: FontWeight.bold,
                //       color: colorScheme.onSurface,
                //     ),
                //   ),

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

    _resume(); // ▶ resume story after close
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final story = _currentStory;
    final group = _currentGroup;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: GestureDetector(
        onTapDown: (_) => _pause(),
        onTapUp: (_) => _resume(),
        onTapCancel: _resume,
        onLongPress: _pause,
        onLongPressUp: _resume,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 300) {
            Navigator.pop(context);
          }
        },
        child: Stack(
          children: [
            // ======================
            // Media
            // ======================
            Positioned.fill(
              child: _buildMedia(story),
            ),

            // ======================
            // Tap Zones
            // ======================
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _previousStory,
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _onStoryFinished,
                  ),
                ),
              ],
            ),

            // ======================
            // Top Overlay
            // ======================
            SafeArea(
              child: Column(
                children: [
                  // Progress Bars
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Row(
                      children: List.generate(
                        group.stories.length,
                            (index) => Expanded(
                          child: Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 2),
                            child: _buildProgressBar(index,context),
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
                        CircleAvatar(
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
                        const SizedBox(width: 8),
                        Text(
                          group.author.name,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timeAgo(story.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                            colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: colorScheme.onSurface,
                          ),
                          onPressed: () => Navigator.pop(context),
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

                  if (story.title != null && story.title!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () {
                          if (story.description != null &&
                              story.description!.isNotEmpty ||
                              _isLongText(story.description!)) {
                            _showDescriptionSheet(
                              context,
                              // story.title ?? "",
                              story.description!,
                            );
                          }
                        },
                        child: Column(
                          children: [
                            Text(
                              story.title!,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),


                            // READ MORE (tap only here)
                            if (_isLongText(story.title!))
                              GestureDetector(
                                onTap: () {
                                  _showDescriptionSheet(
                                    context,
                                    story.title!, // 👈 SHOW TITLE TEXT
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    "Read more",
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                  _buildFooterActions(story,context),
                ],
              ),
            ),
          ],
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
            valueColor: AlwaysStoppedAnimation<Color>(
              colorScheme.onSurface,
            ),
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
          TextButton.icon(
            onPressed: _showViewers,
            icon: Icon(Icons.visibility, color: colorScheme.onSurface),
            label: Text(
              "${story.viewCount}",
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ),
          IconButton(
            onPressed: _deleteStory,
            icon: Icon(Icons.delete, color: colorScheme.onSurface),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Icon(
                story.hasLiked ? Icons.favorite : Icons.favorite_border,
                color: story.hasLiked
                    ? colorScheme.error
                    : colorScheme.onSurface,
                size: 30,
              ),
              onPressed: _handleReaction,
            ),
          ),
        ],
      );
    }
  }


  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}h";
    return "${diff.inDays}d";
  }
}

class _ViewersSheet extends StatelessWidget {
  final Map<String, dynamic> details;

  const _ViewersSheet({required this.details});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final viewers = details['viewers'] as List? ?? [];

    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Viewers (${details['viewerCount']})",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: viewers.isEmpty
                ? Center(
              child: Text(
                "No views yet",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            )
                : ListView.builder(
              itemCount: viewers.length,
              itemBuilder: (context, index) {
                final v = viewers[index];
                final hasLiked = v['reaction_type'] == true;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.surfaceVariant,
                    backgroundImage: v['avatar_url'] != null
                        ? NetworkImage(v['avatar_url'])
                        : null,
                    child: v['avatar_url'] == null
                        ? Text(
                      v['full_name']?[0] ?? "?",
                      style: TextStyle(
                        color: colorScheme.onSurface,
                      ),
                    )
                        : null,
                  ),
                  title: Text(
                    v['full_name'] ?? "Unknown",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  trailing: hasLiked
                      ? Icon(
                    Icons.favorite,
                    color: colorScheme.error,
                  )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }


}