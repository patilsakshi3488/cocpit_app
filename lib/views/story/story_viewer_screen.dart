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
      // Image
      _animController.duration = const Duration(seconds: 5);
      // Preload image? Image.network handles it but we want to start timer after load.
      // For simplicity, start timer immediately.
      // Ideally use `precacheImage`.
      if (mounted) {
         precacheImage(NetworkImage(story.mediaUrl), context).then((_) {
             if (mounted && _currentStory == story) {
                 _animController.forward();
             }
         });
      }
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
    _pause();
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
    _resume();
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

  @override
  Widget build(BuildContext context) {
    final story = _currentStory;
    final group = _currentGroup;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (_) => _pause(),
        onTapUp: (_) => _resume(),
        onTapCancel: () => _resume(),
        onLongPress: _pause,
        onLongPressUp: _resume,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 300) {
            Navigator.pop(context);
          }
        },
        child: Stack(
          children: [
            // Media
            Positioned.fill(
              child: _buildMedia(story),
            ),

            // Tappable Areas
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
                    onTap: _onStoryFinished, // Next
                  ),
                ),
              ],
            ),

            // Overlays
            SafeArea(
              child: Column(
                children: [
                  // Progress Bars
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Row(
                      children: List.generate(group.stories.length, (index) {
                         return Expanded(
                           child: Padding(
                             padding: const EdgeInsets.symmetric(horizontal: 2),
                             child: _buildProgressBar(index),
                           ),
                         );
                      }),
                    ),
                  ),

                  // Header (User Info)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                         CircleAvatar(
                           backgroundImage: group.author.avatar != null
                             ? NetworkImage(group.author.avatar!)
                             : null,
                           child: group.author.avatar == null
                             ? Text(group.author.name[0]) : null,
                         ),
                         const SizedBox(width: 8),
                         Text(
                           group.author.name,
                           style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                         ),
                         const SizedBox(width: 8),
                         Text(
                           _timeAgo(story.createdAt),
                           style: const TextStyle(color: Colors.white70, fontSize: 12)
                         ),
                         const Spacer(),
                         IconButton(
                           icon: const Icon(Icons.close, color: Colors.white),
                           onPressed: () => Navigator.pop(context),
                         ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Footer (Actions)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   if (story.description != null && story.description!.isNotEmpty)
                     Padding(
                       padding: const EdgeInsets.only(bottom: 16),
                       child: Text(
                         story.description!,
                         textAlign: TextAlign.center,
                         style: const TextStyle(color: Colors.white, fontSize: 16),
                       ),
                     ),

                   _buildFooterActions(story),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia(Story story) {
     if (story.mediaType == 'video') {
        if (_videoController != null && _videoController!.value.isInitialized) {
           return Center(
             child: AspectRatio(
               aspectRatio: _videoController!.value.aspectRatio,
               child: VideoPlayer(_videoController!),
             ),
           );
        } else {
           return const Center(child: CircularProgressIndicator());
        }
     } else {
        return Image.network(
           story.mediaUrl,
           fit: BoxFit.contain, // or cover? WhatsApp usually cover but ensures visibility.
           width: double.infinity,
           height: double.infinity,
           loadingBuilder: (ctx, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator());
           },
        );
     }
  }

  Widget _buildProgressBar(int index) {
     if (index < _currentStoryIndex) {
        // Completed
        return const LinearProgressIndicator(value: 1.0, color: Colors.white, backgroundColor: Colors.white24);
     } else if (index == _currentStoryIndex) {
        // Current (Animated)
        return AnimatedBuilder(
           animation: _animController,
           builder: (context, _) => LinearProgressIndicator(
              value: _animController.value,
              color: Colors.white,
              backgroundColor: Colors.white24,
           ),
        );
     } else {
        // Future
        return const LinearProgressIndicator(value: 0.0, color: Colors.white, backgroundColor: Colors.white24);
     }
  }

  Widget _buildFooterActions(Story story) {
    if (story.isAuthor) {
      // Author View
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
             onPressed: _showViewers,
             icon: const Icon(Icons.visibility, color: Colors.white),
             label: Text("${story.viewCount}", style: const TextStyle(color: Colors.white)),
          ),
          IconButton(
            onPressed: _deleteStory,
            icon: const Icon(Icons.delete, color: Colors.white),
          )
        ],
      );
    } else {
      // Viewer View
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           IconButton(
             icon: Icon(
               story.hasLiked ? Icons.favorite : Icons.favorite_border,
               color: story.hasLiked ? Colors.red : Colors.white,
               size: 30,
             ),
             onPressed: _handleReaction,
           ),
           // Maybe Reply field? Not in requirements explicitly ("Allow like/unlike").
           // But WhatsApp has reply. I'll stick to Like.
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
    final viewers = details['viewers'] as List? ?? [];

    return Container(
       decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
       ),
       height: 400,
       child: Column(
         children: [
            Padding(
               padding: const EdgeInsets.all(16),
               child: Text(
                 "Viewers (${details['viewerCount']})",
                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
               ),
            ),
            Expanded(
               child: viewers.isEmpty
                 ? const Center(child: Text("No views yet"))
                 : ListView.builder(
                     itemCount: viewers.length,
                     itemBuilder: (context, index) {
                        final v = viewers[index];
                        final hasLiked = v['reaction_type'] == 'true';
                        return ListTile(
                           leading: CircleAvatar(
                              backgroundImage: v['avatar_url'] != null ? NetworkImage(v['avatar_url']) : null,
                              child: v['avatar_url'] == null ? Text(v['full_name']?[0] ?? "?") : null,
                           ),
                           title: Text(v['full_name'] ?? "Unknown"),
                           trailing: hasLiked ? const Icon(Icons.favorite, color: Colors.red) : null,
                        );
                     },
                 ),
            ),
         ],
       ),
    );
  }
}
