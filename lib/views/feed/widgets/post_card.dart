import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../services/post_provider.dart';
import '../../../../services/feed_service.dart';
import 'poll_analytics_dialog.dart';
import '../../../widgets/poll_widget.dart';
import '../../../widgets/time_ago_widget.dart';
import '../../profile/public_profile_screen.dart';
import '../comments_sheet.dart';
import '../home_screen.dart'; // For VideoPost
import '../../../../services/secure_storage.dart';
import 'share_sheet.dart';
import 'nested_post_preview.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final bool isOwner;
  final bool simpleView;
  final Function(String)? onDelete;
  final Function(String)? onEdit;
  final Function(String, bool)? onPrivacyChange;
  final VoidCallback? onRepost;

  const PostCard({
    super.key,
    required this.post,
    this.isOwner = false,
    this.simpleView = false,
    this.onDelete,
    this.onEdit,
    this.onPrivacyChange,
    this.onRepost,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late Map<String, dynamic> post;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    post = widget.post;
    // Register the post with the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().updatePost(widget.post);
    });

    _loadCurrentUser();
    _checkInitialCommentCount();
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post != oldWidget.post) {
      // If widget updates, update provider too
      context.read<PostProvider>().updatePost(widget.post);
      setState(() {
        post = widget.post;
      });
    }
  }

  Future<void> _checkInitialCommentCount() async {
    // If the feed says 0, double check (workaround for backend bug)
    final initialCount =
        post["comment_count"] ??
        post["comments_count"] ??
        post["_count"]?["comments"] ??
        0;

    int count = 0;
    if (initialCount is int) count = initialCount;
    if (initialCount is String) count = int.tryParse(initialCount) ?? 0;

    if (count == 0) {
      try {
        final comments = await FeedApi.fetchComments(postId);
        if (mounted && comments.isNotEmpty) {
          // Instead of local setState, update provider if possible, but for now
          // let's stick to local + provider sync
          final newMap = Map<String, dynamic>.from(post);
          newMap["comment_count"] = comments.length;
          context.read<PostProvider>().updatePost(newMap);
        }
      } catch (_) {
        // Ignore errors, keep 0
      }
    }
  }

  Future<void> _loadCurrentUser() async {
    final uid = await AppSecureStorage.getCurrentUserId();
    if (mounted) setState(() => currentUserId = uid);
  }

  // Check if post belongs to logged-in user
  bool get isMine {
    final String? authorId = getAuthorId();
    return currentUserId != null && authorId == currentUserId;
  }

  String? getAuthorId() {
    // 1. Check nested objects
    final author = post["author"] ?? post["user"] ?? {};
    String? id =
        author["_id"]?.toString() ??
        author["id"]?.toString() ??
        author["user_id"]?.toString();

    // 2. Check flat share payload keys
    id ??=
        post["post_owner_id"]?.toString() ??
        post["post_author_id"]?.toString() ??
        post["owner_id"]?.toString() ??
        post["author_id"]?.toString() ??
        post["user_id"]?.toString() ??
        post["_id"]?.toString(); // Last resort check

    if (id == null) {
      debugPrint(
        "⚠️ [PostCard] No Author ID found in post: ${post.keys.toList()}",
      );
    }
    return id;
  }

  // Handle differences in ID naming
  String get postId {
    final id = post["post_id"] ?? post["id"] ?? post["_id"] ?? post["_id"];
    return id?.toString() ?? "";
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Listen to changes for this post from the provider
    final providerPost = context.select<PostProvider, Map<String, dynamic>?>(
      (provider) => provider.getPost(postId),
    );

    // Use provider data if available, otherwise fallback to local/widget data
    if (providerPost != null) {
      post = providerPost;
    }

    final List media = post["media"] ?? post["media_urls"] ?? [];

    final normalizedMedia = media.map((m) {
      if (m is String) return {"url": m, "media_type": "image"};
      return m;
    }).toList();

    final pollData = post["poll"];
    final poll = (pollData is Map && pollData["options"] != null)
        ? normalizePoll(Map<String, dynamic>.from(pollData))
        : null;

    return Container(
      margin: widget.simpleView
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(
              vertical: 4.0,
            ), // Maintain space between posts
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _postHeader(theme),
          if (post["content"] != null && post["content"].toString().isNotEmpty)
            _postText(theme),
          if (post["shared_post"] != null)
            NestedPostPreview(
              originalPost: Map<String, dynamic>.from(post["shared_post"]),
            ),
          if (normalizedMedia.isNotEmpty) _postMedia(normalizedMedia),
          if (poll != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: PollWidget(
                postId: postId,
                poll: poll,
                onPollUpdated: (updatedPoll) {
                  if (mounted) {
                    setState(() {
                      post["poll"] = updatedPoll;
                    });
                  }
                },
              ),
            ),
          _postStats(theme),
          Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
          _postActions(theme),
        ],
      ),
    );
  }

  Widget _postHeader(ThemeData theme) {
    final author = post["author"] ?? post["user"] ?? {};
    final String authorName =
        author["full_name"] ??
        author["name"] ??
        post["author_name"] ??
        post["authorName"] ??
        post["user_name"] ??
        "User";
    final String? authorAvatar =
        author["avatar_url"] ??
        author["avatar"] ??
        post["author_avatar"] ??
        post["authorAvatar"];
    final String category = post["category"] ?? post["category_name"] ?? "";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _navigateToProfile,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              backgroundImage: authorAvatar != null
                  ? NetworkImage(authorAvatar)
                  : null,
              child: authorAvatar == null
                  ? Text(
                      authorName.isNotEmpty ? authorName[0] : "?",
                      style: TextStyle(color: theme.primaryColor, fontSize: 14),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _navigateToProfile,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          authorName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (post["created_at"] != null) ...[
                        Text(
                          " • ",
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.5),
                          ),
                        ),
                        TimeAgoWidget(
                          dateTime: DateTime.parse(
                            post["created_at"].toString(),
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (category.isNotEmpty)
                    Text(
                      category,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.6,
                        ),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ),
          _buildPostMenu(theme),
        ],
      ),
    );
  }

  Future<void> _navigateToProfile() async {
    String? authorId = getAuthorId();
    if (authorId == null || authorId.isEmpty) return;

    String? myId = currentUserId;
    if (myId == null) {
      myId = await AppSecureStorage.getCurrentUserId();
      if (mounted) setState(() => currentUserId = myId);
    }

    final bool amIOwner = myId != null && authorId == myId;

    if (amIOwner) {
      Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PublicProfileScreen(userId: authorId),
        ),
      );
    }
  }

  void _onShareTap() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareSheet(post: post),
    );

    if (result == true && mounted) {
      // If we are in the detail screen, we might want to pop back to feed or just show a snackbar
      // But for website parity, a sucessful repost in feed refreshes the feed.
      // Call callback if provided, otherwise do nothing (let parent handle via provider updates if needed)
      widget.onRepost?.call();
    }
  }

  Widget _buildPostMenu(ThemeData theme) {
    // Only show full menu if it's MY post or explicitly passed as owner
    if (isMine || widget.isOwner) {
      final isPrivate = post['visibility'] == 'private';
      final hasPoll = post["poll"] != null;

      return PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') widget.onEdit?.call(postId);
          if (value == 'privacy') {
            widget.onPrivacyChange?.call(postId, !isPrivate);
          }
          if (value == 'delete') widget.onDelete?.call(postId);
          if (value == 'analytics') _showPollAnalytics();
        },
        itemBuilder: (context) => [
          if (hasPoll)
            PopupMenuItem(
              value: 'analytics',
              child: Row(
                children: [
                  Icon(Icons.bar_chart, size: 18, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  const Text("View Poll Analytics"),
                ],
              ),
            ),
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
                Icon(isPrivate ? Icons.public : Icons.lock_outline, size: 18),
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
        child: Icon(
          Icons.more_horiz,
          color: theme.iconTheme.color?.withOpacity(0.6),
          size: 20,
        ),
      );
    }
    // Non-owner menu actions
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'share') {
          _onShareTap();
        }
        if (value == 'report') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Post reported to admins")),
          );
        }
        if (value == 'save') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Post added to favorites")),
          );
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'save',
          child: Row(
            children: [
              Icon(Icons.star_border, size: 18),
              const SizedBox(width: 8),
              const Text("Add to favorites"),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.link, size: 18),
              const SizedBox(width: 8),
              const Text("Copy link"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.flag_outlined, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text("Report", style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      child: Icon(
        Icons.more_horiz,
        color: theme.iconTheme.color?.withOpacity(0.6),
        size: 20,
      ),
    );
  }

  void _showPollAnalytics() {
    final pollData = post["poll"];
    if (pollData == null) return;

    final options = (pollData["options"] as List? ?? []);
    showDialog(
      context: context,
      builder: (ctx) => PollAnalyticsDialog(options: options),
    );
  }

  Widget _postText(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        post["content"],
        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.4),
      ),
    );
  }

  Widget _postMedia(List media) {
    final first = media.first;
    String url = first["url"];
    String type = first["media_type"] ?? "image";

    if (type == "video") {
      return Container(
        height: 300,
        margin: const EdgeInsets.only(top: 8),
        color: Colors.black,
        child: VideoPost(url: url),
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Image.network(url, fit: BoxFit.cover, width: double.infinity),
    );
  }

  Widget _postStats(ThemeData theme) {
    final commentCount =
        post["comment_count"] ??
        post["comments_count"] ??
        post["_count"]?["comments"] ??
        0;
    final likeCount = post["like_count"] ?? post["likes"] ?? 0;

    if (likeCount == 0 && commentCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        "$likeCount likes · $commentCount comments",
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _postActions(ThemeData theme) {
    return Consumer<PostProvider>(
      builder: (context, provider, _) {
        final postData = provider.getPost(postId);
        if (postData == null) return const SizedBox.shrink();

        final bool isLiked = postData["is_liked"] == true;

        return Column(
          children: [
            Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _action(
                  isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  "Like",
                  color: isLiked
                      ? theme.primaryColor
                      : theme.iconTheme.color?.withOpacity(0.7),
                  onTap: () {
                    if (postId.isNotEmpty) provider.toggleLike(postId);
                  },
                  theme: theme,
                ),
                _action(
                  Icons.chat_bubble_outline,
                  "Comment",
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
                              final current =
                                  post["comment_count"] ??
                                  post["comments_count"] ??
                                  0;
                              int count = current is String
                                  ? (int.tryParse(current) ?? 0)
                                  : current;
                              post["comment_count"] = count + 1;
                            });
                          }
                        },
                      ),
                    );
                  },
                  theme: theme,
                ),
                _action(
                  Icons.share_outlined,
                  "Share",
                  onTap: _onShareTap,
                  theme: theme,
                ),
                _action(
                  Icons.bookmark_border,
                  "Save",
                  onTap: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text("Post saved")));
                  },
                  theme: theme,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _action(
    IconData icon,
    String label, {
    Color? color,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    // ICONS ONLY - NO TEXT LABELS
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Icon(
          icon,
          size: 20, // Website icon size
          color: color ?? theme.iconTheme.color?.withOpacity(0.8),
        ),
      ),
    );
  }
}
