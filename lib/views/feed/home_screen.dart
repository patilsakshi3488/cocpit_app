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

import '../profile/public_profile_screen.dart';
import 'create_career_moment_screen.dart';
import 'career_moment_viewer.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/poll_widget.dart';
import '../post/create_post_screen.dart';
import '../bottom_navigation.dart';
import '../../main.dart'; // To access routeObserver

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
  // 📌 STORIES DATA
  // =========================
  final List<Map<String, dynamic>> careerMoments = [
    {
      'name': 'You',
      'isMine': true,
      'stories': [
        {
          'image': 'lib/images/profile.png',
          'text': 'Just sharing my latest update with my close friends!',
          'time': '1m ago',
        },
      ],
      'profile': 'lib/images/profile.png',
      'image': 'lib/images/profile.png',
    },
    {
      'name': 'Mike Torres',
      'isMine': false,
      'image': 'lib/images/story1.png',
      'profile': 'lib/images/profile2.jpg',
      'stories': [
        {
          'image': 'lib/images/story1.png',
          'text': 'Sneak peek of our latest feature!',
          'time': '6h ago',
        },
      ],
    },
    {
      'name': 'James Wilson',
      'isMine': false,
      'image': 'lib/images/story4.png',
      'profile': 'lib/images/profile3.jpg',
      'stories': [
        {
          'image': 'lib/images/story4.png',
          'text': 'Insights from our data analysis project.',
          'time': '8h ago',
        },
      ],
    },
  ];

  // =========================
  // 🔁 INIT
  // =========================
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(_onSearchFocusChange);

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

  // ... (Search Logic unchanged) ...

  // =========================
  // 🔍 SEARCH LOGIC
  // =========================
  void _onSearchFocusChange() {
    if (_searchFocusNode.hasFocus && _searchController.text.isNotEmpty) {
      _showSearchOverlay();
    } else {
      Future.delayed(const Duration(milliseconds: 200), _closeOverlay);
    }
  }

  void _onSearchChanged(String query) {
    _lastQuery = query;
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      _closeOverlay();
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _hasError = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        setState(() => _isSearching = true);
        final token = await AppSecureStorage.getAccessToken();
        if (token == null) return;

        final results = await UserSearchService.searchUsers(
          query: query,
          token: token,
        );

        if (mounted && _lastQuery == query) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
          _showSearchOverlay();
        }
      } catch (_) {
        setState(() {
          _hasError = true;
          _isSearching = false;
        });
        _showSearchOverlay();
      }
    });
  }

  void _showSearchOverlay() {
    _closeOverlay();
    _overlayEntry = _createSearchOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createSearchOverlayEntry() {
    final theme = Theme.of(context);

    return OverlayEntry(
      builder: (_) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: const Offset(0, 50),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            child: ListView(
              shrinkWrap: true,
              children: _searchResults
                  .map(
                    (u) => ListTile(
                      title: Text(u.fullName),
                      onTap: () {
                        _closeOverlay();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PublicProfileScreen(userId: u.id),
                          ),
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

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
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _onSearchChanged,
        layerLink: _layerLink,
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
            if (index == 1) return _careerMomentsBar(theme);
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
    return Padding(
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
                Text(
                  post["category_name"] ?? "",
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(Icons.more_vert, color: theme.iconTheme.color),
        ],
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.thumb_up, size: 14, color: theme.primaryColor),
          const SizedBox(width: 4),
          Text("${post["like_count"] ?? 0}", style: theme.textTheme.bodySmall),
          const SizedBox(width: 12),
          Text(
            "${post["comment_count"] ?? 0} comments", // Needs backend to send comment_count
            style: theme.textTheme.bodySmall,
          ),
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
                  // Optimistic Increment
                  if (mounted) {
                    setState(() {
                      post["comment_count"] = (post["comment_count"] ?? 0) + 1;
                    });
                  }
                  // Fetch fresh data from DB to get correct comment count
                  _refreshPost(post);
                },
              ),
            );
          },
          child: _action(Icons.chat_bubble_outline, "Comment", theme: theme),
        ),

        // SHARE
        InkWell(
          onTap: () {
            Clipboard.setData(
              ClipboardData(text: "https://example.com/post/$postId"),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Link copied to clipboard")),
            );
          },
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
            color: color ?? theme.iconTheme.color?.withOpacity(0.7),
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
        Text(
          "View All",
          style: TextStyle(color: theme.primaryColor, fontSize: 14),
        ),
      ],
    ),
  );

  Widget _careerMomentsBar(ThemeData theme) {
    double itemWidth = MediaQuery.of(context).size.width > 600 ? 150 : 120;

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: careerMoments.length,
        itemBuilder: (context, index) {
          final m = careerMoments[index];
          return GestureDetector(
            onTap: () {
              if (m['isMine']) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateCareerMomentScreen(),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CareerMomentViewer(
                      users: careerMoments,
                      initialUserIndex: index,
                    ),
                  ),
                );
              }
            },
            child: Container(
              width: itemWidth,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: !m['isMine']
                    ? DecorationImage(
                        image: AssetImage(m['image']),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: m['isMine'] ? theme.primaryColor : theme.cardColor,
              ),
              child: Stack(
                children: [
                  if (m['isMine'])
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
                  if (!m['isMine'])
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
                              backgroundImage: AssetImage(m['profile']),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
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
