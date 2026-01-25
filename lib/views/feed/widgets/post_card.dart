import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../services/feed_service.dart';
import 'poll_analytics_dialog.dart';
import '../../../widgets/poll_widget.dart';
import '../../profile/public_profile_screen.dart';
import '../comments_sheet.dart';
import '../home_screen.dart'; // For VideoPost
import '../../../../services/secure_storage.dart';
import '../../profile/profile_screen.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final bool isOwner;
  final bool simpleView;
  final Function(String)? onDelete;
  final Function(String)? onEdit;
  final Function(String, bool)? onPrivacyChange;

  const PostCard({
    super.key,
    required this.post,
    this.isOwner = false,
    this.simpleView = false,
    this.onDelete,
    this.onEdit,
    this.onPrivacyChange,
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
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final uid = await AppSecureStorage.getCurrentUserId();
    if (mounted) setState(() => currentUserId = uid);
  }

  // Check if post belongs to logged-in user
  bool get isMine {
    final authorId =
        post["author_id"]?.toString() ?? post["user_id"]?.toString();
    return currentUserId != null && authorId == currentUserId;
  }

  // Handle differences in ID naming
  String get postId =>
      post["post_id"]?.toString() ?? post["id"]?.toString() ?? "";

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
          : const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: widget.simpleView
          ? BoxDecoration(
              color: theme.cardColor,
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                  width: 8, // Thicker separator for flat feed
                ),
              ),
            )
          : BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _postHeader(theme),
          if (post["content"] != null && post["content"].toString().isNotEmpty)
            _postText(theme),
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
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.5)),
          _postActions(theme),
        ],
      ),
    );
  }

  Widget _postHeader(ThemeData theme) {
    String authorName = post["author_name"] ?? post["user"]?["name"] ?? "User";
    String? authorAvatar = post["author_avatar"] ?? post["user"]?["avatar"];
    String category = post["category"] ?? post["category_name"] ?? "";

    return GestureDetector(
      onTap: () async {
        // If explicitly set as owner (e.g. on profile page), maybe do nothing?
        // But user requirement says: "If viewing own profile ... show editable profile UI"
        // If I am on my profile, clicking my posts shouldn't navigate me to my profile again?
        // Let's stick to the condition: if isMine -> ProfileScreen, else PublicProfileScreen.

        String? authorId =
            post["author_id"]?.toString() ?? post["user_id"]?.toString();

        if (authorId == null) return;

        if (isMine) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PublicProfileScreen(userId: authorId),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage: authorAvatar != null
                  ? NetworkImage(authorAvatar)
                  : null,
              child: authorAvatar == null
                  ? Text(authorName.isNotEmpty ? authorName[0] : "?")
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authorName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (category.isNotEmpty)
                    Text(category, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            _buildPostMenu(theme),
          ],
        ),
      ),
    );
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
        child: Icon(Icons.more_horiz, color: theme.iconTheme.color),
      );
    }
    // For other users, show generic report/share options or nothing?
    // User requirement: "Posts should NOT show edit/delete/privacy options"
    // I'll leave a simple "more" icon that currently does nothing or maybe share
    // For now, returning standard icon but with no items if not owner?
    // Or simpler: just hide it if not owner?
    // Usually there is "Report" or "Share". existing code returned Icon(more_vert).
    // I'll keep it as Icon(more_vert) for consistency but maybe make it do nothing or show minimal menu.
    // For now, I'll return empty if not owner to be strict per user request?
    // "Posts should NOT show edit/delete/privacy options" -> doesn't say "no menu".
    // I'll stick to the previous behavior for non-owners: Icon(more_vert)
    return Icon(Icons.more_vert, color: theme.iconTheme.color);
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(post["content"], style: theme.textTheme.bodyMedium),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.thumb_up, size: 14, color: theme.primaryColor),
          const SizedBox(width: 4),
          Text("$likeCount", style: theme.textTheme.bodySmall),
          const SizedBox(width: 12),
          Text("$commentCount comments", style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _postActions(ThemeData theme) {
    final isLiked = post["is_liked"] == true;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        InkWell(
          onTap: () async {
            try {
              setState(() {
                post["is_liked"] = !post["is_liked"];
              });
              await FeedApi.toggleLike(postId);
            } catch (_) {}
          },
          child: _action(
            isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
            "Like",
            color: isLiked ? theme.primaryColor : null,
            theme: theme,
          ),
        ),
        InkWell(
          onTap: () async {
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) =>
                  CommentsSheet(postId: postId, onCommentAdded: () {}),
            );
          },
          child: _action(Icons.chat_bubble_outline, "Comment", theme: theme),
        ),
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
}
