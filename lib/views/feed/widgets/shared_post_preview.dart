import 'package:flutter/material.dart';
import '../post_detail_screen.dart';
import '../../profile/public_profile_screen.dart';

class SharedPostPreview extends StatelessWidget {
  final Map<String, dynamic> sharedPost;
  final bool isMe;
  final String? messageText;
  final bool isInteractive;

  const SharedPostPreview({
    super.key,
    required this.sharedPost,
    required this.isMe,
    this.messageText,
    this.isInteractive = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // EXTRACT METADATA (Support both rich payload and nested legacy structure)
    // Rich payload fields: post_owner_name, post_image, post_text, etc.
    // STRICT BACKEND CONTRACT (Matches Website Logic)
    final author = sharedPost['author'] as Map<String, dynamic>?;
    final String? authorId = author?['user_id']?.toString();
    final String authorName = author?['full_name'] ?? 'Unknown User';
    final String? authorAvatar = author?['avatar_url'];

    final postText = sharedPost['post_text'] ?? sharedPost['content'] ?? '';

    final postImage =
        sharedPost['post_image'] ??
        (sharedPost['media'] is List && (sharedPost['media'] as List).isNotEmpty
            ? (sharedPost['media'] as List).first['url']
            : null);

    final postType = sharedPost['post_type']?.toString().toLowerCase() ?? '';
    final isPoll = postType == 'poll' || sharedPost['poll'] != null;
    final isVideo =
        postType == 'video' ||
        (sharedPost['media'] is List &&
            (sharedPost['media'] as List).isNotEmpty &&
            (sharedPost['media'] as List).first['media_type'] == 'video');

    // ACCESSIBILITY LOGIC
    final bool isDeleted = sharedPost['deleted'] == true;
    final String visibility = (sharedPost['visibility'] ?? 'public')
        .toString()
        .toLowerCase();
    final String category =
        (sharedPost['category'] ?? sharedPost['category_name'] ?? '')
            .toString();

    // Private: Only for the author
    final bool isPrivate = visibility == 'private';

    // Professional: Always public-like behavior
    final bool isProfessional =
        category == 'Professional' || visibility == 'public';

    // Personal: Only for followers (if not Professional)
    final bool isPersonal =
        (category == 'Personal' || visibility == 'personal') && !isProfessional;

    // Explicit permission/relationship checks (Unfollowed/Blocked cases)
    final bool isFollowing =
        sharedPost['is_following'] == true || author?['is_following'] == true;

    final bool isAccessible =
        sharedPost['is_accessible'] == true ||
        sharedPost['is_viewable'] == true ||
        sharedPost['can_view'] == true;

    final bool lacksPermission =
        sharedPost['is_accessible'] == false ||
        sharedPost['is_viewable'] == false ||
        sharedPost['can_view'] == false ||
        sharedPost['lacks_permission'] == true;

    // Use current relationship status ONLY for Personal posts
    final bool relationshipBroken = isPersonal && !isFollowing && !isAccessible;
    final bool isReserved =
        sharedPost.isEmpty ||
        (sharedPost['author'] == null &&
            (sharedPost['content'] == null || sharedPost['content'].isEmpty));

    if (isDeleted ||
        (isPrivate && lacksPermission) ||
        isReserved ||
        lacksPermission ||
        relationshipBroken) {
      return AbsorbPointer(
        absorbing: !isInteractive,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: 0.5),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock,
                    color: Colors.orangeAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: authorId == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PublicProfileScreen(userId: authorId),
                            ),
                          );
                        },
                  child: Text(
                    "Post by $authorName",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  (isPrivate || isPersonal)
                      ? "This is a Personal post.\nConnect with the user to view it."
                      : "This content is no longer available.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AbsorbPointer(
      absorbing: !isInteractive,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.3),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1ï¸âƒ£ HEADER: Author Info (Target: Profile)
            InkWell(
              onTap: () {
                if (authorId != null && authorId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PublicProfileScreen(userId: authorId),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: authorAvatar != null
                          ? NetworkImage(authorAvatar)
                          : null,
                      backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                      child: authorAvatar == null
                          ? Text(
                              authorName.isNotEmpty ? authorName[0] : '?',
                              style: const TextStyle(fontSize: 8),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: authorName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            TextSpan(
                              text: " Â· Reposted",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2ï¸âƒ£ BODY: Media & Caption (Target: Post Detail)
            InkWell(
              onTap: () {
                // Ensure we have a valid post ID or payload
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostDetailScreen(post: sharedPost),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (postImage != null)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: 1.2,
                          child: Image.network(
                            postImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.black26,
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.white24,
                                  ),
                                ),
                          ),
                        ),
                        if (isVideo)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                      ],
                    )
                  else if (isPoll)
                    Container(
                      height: 100,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.poll_outlined,
                              color: Colors.white54,
                              size: 30,
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Tap to view Poll",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (postText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        postText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          height: 1.4,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            // 3ï¸âƒ£ FOOTER / MESSAGE (Optional message sent with post)
            if (messageText != null && messageText!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  color: Colors.white.withValues(alpha: 0.01),
                ),
                child: Text(
                  messageText!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // 4ï¸âƒ£ VIEW DETAILS CTA
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostDetailScreen(post: sharedPost),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  border: Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      size: 14,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "View Post Details",
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

