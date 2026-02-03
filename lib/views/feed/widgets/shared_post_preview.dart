import 'package:flutter/material.dart';
import '../../profile/public_profile_screen.dart';
import '../../../widgets/poll_widget.dart';
import '../../../widgets/time_ago_widget.dart';

class SharedPostPreview extends StatelessWidget {
  final Map<String, dynamic> sharedPost;
  final bool isMe;
  final String? messageText;

  const SharedPostPreview({
    super.key,
    required this.sharedPost,
    required this.isMe,
    this.messageText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 1️⃣ HANDLE ACCESSIBILITY (locked state)
    final dynamic accessVal = sharedPost['is_accessible'];
    final bool isAccessible = accessVal != false && accessVal != 0 && accessVal != "false";
    
    if (!isAccessible) {
      return _buildInaccessiblePlaceholder(theme);
    }

    // 2️⃣ EXTRACT METADATA
    final author = sharedPost['author'] ?? {};
    final String authorName =
        sharedPost['post_owner_name'] ??
        author['full_name'] ??
        author['name'] ??
        'User';
    final String? authorAvatar =
        sharedPost['post_owner_avatar'] ??
        author['avatar_url'] ??
        author['avatar'];
    final String? authorId =
        (sharedPost['post_owner_id'] ?? author['id'] ?? author['_id'])
            ?.toString();
    final String postText =
        sharedPost['post_text'] ?? sharedPost['content'] ?? '';
    final List media = sharedPost['media'] ?? sharedPost['media_urls'] ?? [];

    // Poll Data normalization (similar to PostCard)
    final pollData = sharedPost['poll'];
    final Map<String, dynamic>? poll =
        (pollData is Map && pollData["options"] != null)
        ? _normalizePoll(Map<String, dynamic>.from(pollData))
        : null;

    final String? createdAt = sharedPost['created_at']?.toString();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2735), // Website-like deep dark background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Author + Timestamp
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (authorId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PublicProfileScreen(userId: authorId),
                        ),
                      );
                    }
                  },
                  child: CircleAvatar(
                    radius: 16,
                    backgroundImage: authorAvatar != null
                        ? NetworkImage(authorAvatar)
                        : null,
                    child: authorAvatar == null
                        ? Text(authorName.isNotEmpty ? authorName[0] : "?")
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    children: [
                      Text(
                        authorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (createdAt != null) ...[
                        const SizedBox(height: 2),
                        TimeAgoWidget(
                          dateTime: DateTime.parse(createdAt),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                    ],
                  ),
                ),
                ),
              ],
            ),
          ),

          // Content
          if (postText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                postText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Media
          if (media.isNotEmpty) _buildMediaPreview(media),

          // Poll
          if (poll != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: PollWidget(
                postId: sharedPost['post_id']?.toString() ?? "",
                poll: poll,
                onPollUpdated:
                    (_) {}, // Read-only in preview or handled by PollWidget
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInaccessiblePlaceholder(ThemeData theme) {
    final reason = sharedPost['reason'] ?? 'unknown';
    String primaryMessage = "Post unavailable";
    String secondaryMessage = "";

    if (reason == "private") {
      primaryMessage = "This post is private.";
      secondaryMessage = "";
    } else if (reason == "personal_connection") {
      primaryMessage = "This is a Personal post.";
      secondaryMessage = "Connect with the user to view it.";
    } else if (reason == "unknown") {
      primaryMessage = "This post is not available.";
      secondaryMessage = "";
    }

    final authorName =
        sharedPost['author']?['full_name'] ??
        sharedPost['post_owner_name'] ??
        "Unknown User";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2735),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock,
              color: Color(0xFFEBB637), // Specific LinkedIn lock color
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Content Unavailable",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15, // Slightly smaller/regular bold
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Post by $authorName",
            style: const TextStyle(
              color: Color(0xFF70B5F9), // Lighter blue for link
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            primaryMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          if (secondaryMessage.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              secondaryMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaPreview(List media) {
    final first = media.first;
    final url = first is String ? first : first['url'];
    final type = first is Map ? first['media_type'] : 'image';

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.network(url, fit: BoxFit.cover, width: double.infinity),
          if (type == 'video')
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 30,
              ),
            ),
        ],
      ),
    );
  }

  Map<String, dynamic> _normalizePoll(Map<String, dynamic> poll) {
    final options = (poll["options"] as List? ?? [])
        .map(
          (o) => {
            "option_id": o["option_id"]?.toString() ?? "",
            "option_text": o["option_text"] ?? "",
            "vote_count": o["vote_count"] is int
                ? o["vote_count"]
                : int.tryParse(o["vote_count"]?.toString() ?? "0") ?? 0,
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
}
