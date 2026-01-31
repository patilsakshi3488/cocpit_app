import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'dart:async';
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../../services/feed_service.dart';
import 'comments_sheet.dart';
import '../../models/search_user.dart';
import '../../services/user_search_service.dart';
import '../../services/secure_storage.dart';
import '../story/story_tray.dart';
import '../profile/public_profile_screen.dart';
import 'create_career_moment_screen.dart';
import 'career_moment_viewer.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/poll_widget.dart';
import '../../widgets/time_ago_widget.dart';
import 'search_screen.dart';
import '../post/create_post_screen.dart';
import '../profile/profile_screen.dart';
import '../../main.dart'; // To access routeObserver
import '../bottom_navigation.dart';
import '../../services/notification_service.dart';
import 'widgets/edit_post_modal.dart';
import 'widgets/share_sheet.dart';

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

  void _onShareTap(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareSheet(post: post),
    );
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

            return _postViewFromApi(feedPosts[feedIndex], theme);
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
  Widget _postViewFromApi(Map<String, dynamic> post, ThemeData theme) {
    final List media = post["media"] as List? ?? [];
    final pollData = post["poll"];
    final poll = (pollData is Map && pollData["options"] != null)
        ? normalizePoll(Map<String, dynamic>.from(pollData))
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: theme.cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _postHeader(post, theme),
          if (post["content"] != null && post["content"].toString().isNotEmpty)
            _postText(post, theme),
          if (media.isNotEmpty) _postMedia(media),
          if (poll != null)
            PollWidget(
              postId: post["post_id"]?.toString() ?? "",
              poll: poll,
              onPollUpdated: (updatedPoll) {
                if (mounted) {
                  setState(() {
                    post["poll"] = updatedPoll;
                  });
                }
              },
            ),
          _postStats(post, theme),
          const Divider(height: 1),
          _postActions(post, theme),
        ],
      ),
    );
  }

  Widget _postHeader(Map<String, dynamic> post, ThemeData theme) {
    return GestureDetector(
      onTap: () async {
        if (post["author_id"] != null) {
          final currentUserJson = await AppSecureStorage.getUser();
          if (currentUserJson != null) {
            final currentUser = jsonDecode(currentUserJson);
            final currentUserId =
                currentUser['id']?.toString() ??
                currentUser['user_id']?.toString();
            final authorId = post["author_id"].toString();

            debugPrint("🔍 CHECK: User $currentUserId vs Author $authorId");

            if (currentUserId == authorId) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              return;
            }
          }

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    PublicProfileScreen(userId: post["author_id"].toString()),
              ),
            );
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage: post["author_avatar"] != null
                  ? NetworkImage(post["author_avatar"])
                  : null,
              child: post["author_avatar"] == null
                  ? Text(post["author_name"]?[0] ?? "?")
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post["author_name"] ?? "",
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        post["category_name"] ?? "",
                        style: theme.textTheme.bodySmall,
                      ),
                      if (post["created_at"] != null) ...[
                        Text(" • ", style: theme.textTheme.bodySmall),
                        TimeAgoWidget(
                          dateTime: DateTime.parse(
                            post["created_at"].toString(),
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            _buildPostMenu(post, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPostMenu(Map<String, dynamic> post, ThemeData theme) {
    final postId = post['post_id']?.toString() ?? post['id']?.toString() ?? "";
    final isPrivate = post['visibility'] == 'private';

    // Check ownership
    bool isMine = false;
    // We can use a simple check or more robust one
    final authorId = post["author_id"]?.toString();
    // Assuming currentUserId logic exists or use a simple check

    return FutureBuilder<String?>(
      future: AppSecureStorage.getCurrentUserId(),
      builder: (context, snapshot) {
        final currentUserId = snapshot.data;
        isMine = currentUserId != null && authorId == currentUserId;

        if (isMine) {
          return PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') _handleEditPost(postId);
              if (value == 'privacy') _handlePrivacyChange(postId, !isPrivate);
              if (value == 'delete') _handleDeletePost(postId);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text("Edit Post"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'privacy',
                child: Row(
                  children: [
                    Icon(
                      isPrivate ? Icons.public : Icons.lock_outline,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(isPrivate ? "Make Public" : "Make Private"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text("Delete", style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: Icon(Icons.more_vert, color: theme.iconTheme.color),
          );
        }

        return PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'share') _onShareTap(post);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, size: 18),
                  SizedBox(width: 8),
                  Text("Share"),
                ],
              ),
            ),
          ],
          child: Icon(Icons.more_vert, color: theme.iconTheme.color),
        );
      },
    );
  }

  Widget _postText(Map<String, dynamic> post, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(post["content"], style: theme.textTheme.bodyMedium),
    );
  }

  Widget _postMedia(List media) {
    final first = media.first;

    if (first["media_type"] == "video") {
      return Container(
        height: 300,
        margin: const EdgeInsets.only(top: 8),
        color: Colors.black,
        child: VideoPost(url: first["url"]),
      );
    }

    // IMAGE
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Image.network(
        first["url"],
        fit: BoxFit.cover,
        width: double.infinity,
      ),
    );
  }

  Widget _postStats(Map<String, dynamic> post, ThemeData theme) {
    final commentCount =
        post["comment_count"] ?? // Exact match for your API response
            post["rowCount"] ??      // Fallback for your detail view
            0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.thumb_up, size: 14, color: theme.primaryColor),
          const SizedBox(width: 4),
          Text("${post["like_count"] ?? 0}", style: theme.textTheme.bodySmall),
          const SizedBox(width: 12),
          Text("$commentCount ${commentCount == 1 ? 'comment' : 'comments'}",
              style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _postActions(Map<String, dynamic> post, ThemeData theme) {
    final isLiked = post["is_liked"] == true;
    final postId = post["post_id"].toString();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // LIKE
        InkWell(
          onTap: () async {
            // Optimistic Update
            final previousLiked = isLiked;
            final previousCount = post["like_count"] ?? 0;

            if (mounted) {
              setState(() {
                post["is_liked"] = !isLiked;
                post["like_count"] = isLiked
                    ? (previousCount - 1)
                    : (previousCount + 1);
              });
            }

            try {
              // 1. Send Request
              await FeedApi.toggleLike(postId);

              // 2. Fetch fresh data from DB to ensure accurate count
              await _refreshPost(post);
            } catch (e) {
              debugPrint("❌ Like failed: $e");
              // Revert on failure
              if (mounted) {
                setState(() {
                  post["is_liked"] = previousLiked;
                  post["like_count"] = previousCount;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to like post")),
                );
              }
            }
          },
          child: _action(
            isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
            "Like",
            color: isLiked ? theme.primaryColor : null,
            theme: theme,
          ),
        ),

        // COMMENT
        InkWell(
          onTap: () async {

            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => CommentsSheet(
                postId: postId,
                onCommentAdded: () {

                  if (mounted) {
                    setState(() {
                      // Increment local count
                      int currentCount() {
                        final c =
                            post["comment_count"] ?? // Matches "comment_count": 7 in your JSON
                                post["rowCount"] ??
                                post["comments_count"];

                        if (c is int) return c;
                        if (c is String) return int.tryParse(c) ?? 0;
                        return 0;
                      }

                      // Update preferred field
                      post["comment_count"] = currentCount() + 1;
                      debugPrint("count : "+currentCount().toString());
                    });
                  }
                },
              ),
            );
          },
          child: _action(Icons.chat_bubble_outline, "Comment", theme: theme),
        ),

        // SHARE
        InkWell(
          onTap: () => _onShareTap(post),
          child: _action(Icons.share_outlined, "Share", theme: theme),
        ),
      ],
    );
  }

  Widget _action(
    IconData icon,
    String label, {
    Color? color,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: color ?? theme.iconTheme.color?.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color ?? theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

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
