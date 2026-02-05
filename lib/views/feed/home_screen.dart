import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'dart:async';
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../../services/feed_service.dart';
import '../post/create_post_screen.dart';
import '../../main.dart'; // To access routeObserver
import '../bottom_navigation.dart';
import '../../services/notification_service.dart';
import 'widgets/edit_post_modal.dart';
import 'widgets/share_sheet.dart';
import 'widgets/post_card.dart';
import '../../models/search_user.dart';
import '../../services/user_search_service.dart';
import '../../services/secure_storage.dart';
import '../story/story_tray.dart';
import '../profile/public_profile_screen.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/poll_widget.dart';
import 'search_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, RouteAware {
  // =========================
  // 🔥 FEED STATE
  // =========================
  List<Map<String, dynamic>> feedPosts = [];
  bool isFeedLoading = false;
  bool hasMoreFeeds = true;

  String? cursorCreatedAt;
  String? cursorPostId;

  final ScrollController _scrollController = ScrollController();

  // =========================
  // 🔍 SEARCH STATE
  // =========================
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  List<SearchUser> _searchResults = [];
  bool _isSearching = false;
  bool _hasError = false;
  String _lastQuery = "";
  Timer? _debounce;

  // =========================
  // 🔁 INIT
  // =========================
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initial Fetch
    NotificationService().loadNotifications();

    // Listen for Real-time Toasts
    // Initial Fetch
    NotificationService().loadNotifications();

    // Listeners handled globally now by NotificationWrapper

    fetchAllFeeds();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        fetchAllFeeds();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    // User returned to HomeScreen from another page
    debugPrint("🔄 Returning to HomeScreen, refreshing feed...");
    cursorCreatedAt = null;
    cursorPostId = null;
    hasMoreFeeds = true;
    feedPosts.clear();
    fetchAllFeeds();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      cursorCreatedAt = null;
      cursorPostId = null;
      hasMoreFeeds = true;
      feedPosts.clear();
      fetchAllFeeds();
    }
  }

  // =========================
  // 🔥 FETCH FEEDS (API)
  // =========================
  Future<void> fetchAllFeeds() async {
    if (isFeedLoading || !hasMoreFeeds) return;

    if (mounted) setState(() => isFeedLoading = true);

    try {
      final response = await FeedApi.fetchFeed(
        cursorCreatedAt: cursorCreatedAt,
        cursorPostId: cursorPostId,
      );

      final List<Map<String, dynamic>> newPosts =
          (response["posts"] as List? ?? [])
              .whereType<Map<String, dynamic>>()
              .toList();

      if (mounted) {
        setState(() {
          feedPosts.addAll(newPosts);
        });
      }

      final nextCursor = response["nextCursor"];
      if (nextCursor == null) {
        hasMoreFeeds = false;
      } else {
        cursorCreatedAt = nextCursor["cursorCreatedAt"];
        cursorPostId = nextCursor["cursorPostId"];
      }
    } catch (e) {
      debugPrint("❌ Feed API error: $e");
    }

    if (mounted) setState(() => isFeedLoading = false);
  }

  // =========================
  // 🔄 REFRESH SINGLE POST
  // =========================
  Future<void> _refreshPost(Map<String, dynamic> post) async {
    final postId = post["post_id"]?.toString();
    if (postId == null) return;

    try {
      final updatedPost = await FeedApi.fetchSinglePost(postId);
      if (updatedPost != null && mounted) {
        setState(() {
          // Update the specific post object in the list
          final index = feedPosts.indexOf(post);
          if (index != -1) {
            feedPosts[index] = updatedPost;
          } else {
            // Fallback: update the map reference passed in if it's not found in list (unlikely)
            post.addAll(updatedPost);
          }
        });
      }
    } catch (e) {
      debugPrint("❌ Failed to refresh post: $e");
    }
  }

  Future<void> _handleDeletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text("Are you sure you want to delete this post?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FeedApi.deletePost(postId);
        if (mounted) {
          setState(() {
            feedPosts.removeWhere(
              (p) =>
                  (p['post_id']?.toString() ?? p['id']?.toString()) == postId,
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Post deleted successfully")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Failed to delete: $e")));
        }
      }
    }
  }

  Future<void> _handleEditPost(String postId) async {
    final postIndex = feedPosts.indexWhere(
      (p) => (p['post_id']?.toString() ?? p['id']?.toString()) == postId,
    );
    if (postIndex == -1) return;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditPostModal(post: feedPosts[postIndex]),
    );

    if (result == true) {
      _refreshPost(feedPosts[postIndex]);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post updated successfully")),
      );
    }
  }

  Future<void> _handlePrivacyChange(String postId, bool isPrivate) async {
    try {
      await FeedApi.setPostVisibility(postId, isPrivate);
      if (mounted) {
        setState(() {
          final index = feedPosts.indexWhere(
            (p) => (p['post_id']?.toString() ?? p['id']?.toString()) == postId,
          );
          if (index != -1) {
            feedPosts[index]['visibility'] = isPrivate ? 'private' : 'public';
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Post visibility updated to ${isPrivate ? 'private' : 'public'}",
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update visibility")),
        );
      }
    }
  }

  // ... (Search Logic unchanged) ...

  // =========================
  // 🖥 UI
  // =========================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final shouldRefresh = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
          if (shouldRefresh == true) {
            cursorCreatedAt = null;
            cursorPostId = null;
            hasMoreFeeds = true;
            feedPosts.clear();
            fetchAllFeeds();
          }
        },
        backgroundColor: theme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      appBar: AppTopBar(
        searchType: SearchType.feed,
        onSearchTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          );
        },
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          cursorCreatedAt = null;
          cursorPostId = null;
          hasMoreFeeds = true;
          feedPosts.clear();
          await fetchAllFeeds();
        },
        child: ListView.builder(
          controller: _scrollController,
          itemCount: feedPosts.length + 6,
          itemBuilder: (context, index) {
            if (index == 0) return _storiesHeader(theme);
            if (index == 1) return const StoryTray();
            if (index == 2) return const SizedBox(height: 20);
            if (index == 3) return Divider(color: theme.dividerColor);
            if (index == 4) return const SizedBox(height: 10);

            final feedIndex = index - 5;
            if (feedIndex >= feedPosts.length) {
              return isFeedLoading
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : const SizedBox();
            }

            return PostCard(
              post: feedPosts[feedIndex],
              onDelete: _handleDeletePost,
              onEdit: _handleEditPost,
              onPrivacyChange: _handlePrivacyChange,
              onRepost: () {
                cursorCreatedAt = null;
                cursorPostId = null;
                hasMoreFeeds = true;
                feedPosts.clear();
                fetchAllFeeds();
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 0),
    );
  }

  int asInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  Map<String, dynamic> normalizePoll(Map<String, dynamic> poll) {
    final options = (poll["options"] as List? ?? [])
        .map(
          (o) => {
            "option_id": o["option_id"]?.toString() ?? "",
            "option_text": o["option_text"] ?? "",
            "vote_count": asInt(o["vote_count"]),
          },
        )
        .toList();

    return {
      "poll_id": poll["poll_id"]?.toString() ?? "",
      "options": options,
      "user_vote": poll["user_vote"]?.toString(),
      "is_active": poll["is_active"] == true,
      "duration": poll["duration"] ?? "0",
    };
  }

  // =========================
  // 🧱 POST VIEW (LinkedIn Style - No Card)
  // =========================

  // =========================
  // 📌 STORIES
  // =========================
  Widget _storiesHeader(ThemeData theme) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Stories", style: theme.textTheme.titleLarge),
        // Text(
        //   "View All",
        //   style: TextStyle(color: theme.primaryColor, fontSize: 14),
        // ),
      ],
    ),
  );

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }
}

class VideoPost extends StatefulWidget {
  final String url;
  const VideoPost({super.key, required this.url});

  @override
  State<VideoPost> createState() => _VideoPostState();
}

class _VideoPostState extends State<VideoPost> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
    );
    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: false,
      looping: false,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _chewieController != null &&
            _chewieController!.videoPlayerController.value.isInitialized
        ? Chewie(controller: _chewieController!)
        : const Center(child: CircularProgressIndicator());
  }
}
