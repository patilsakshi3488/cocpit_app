import 'package:flutter/material.dart';
import '../post_detail_screen.dart';
import '../../profile/public_profile_screen.dart';

class NestedPostPreview extends StatelessWidget {
  final Map<String, dynamic> originalPost;
  final bool isInteractive;

  const NestedPostPreview({
    super.key,
    required this.originalPost,
    this.isInteractive = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // STRICT BACKEND CONTRACT (Matches Website Logic)
    final author = originalPost['author'] as Map<String, dynamic>?;
    final String? authorId = author?['user_id']?.toString();
    final String authorName = author?['full_name'] ?? 'Unknown User';
    final String? authorAvatar = author?['avatar_url'];

    // CHECK IF POST IS INACCESSIBLE
    final bool isDeleted = originalPost['deleted'] == true;
    final String visibility = (originalPost['visibility'] ?? 'public')
        .toString()
        .toLowerCase();
    final String category =
        (originalPost['category'] ?? originalPost['category_name'] ?? '')
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
        originalPost['is_following'] == true || author?['is_following'] == true;

    final bool isAccessible =
        originalPost['is_accessible'] == true ||
        originalPost['is_viewable'] == true ||
        originalPost['can_view'] == true;

    final bool lacksPermission =
        originalPost['is_accessible'] == false ||
        originalPost['is_viewable'] == false ||
        originalPost['can_view'] == false ||
        originalPost['lacks_permission'] == true;

    // Use current relationship status ONLY for Personal posts
    final bool relationshipBroken = isPersonal && !isFollowing && !isAccessible;

    // If we have no author and no content, it's likely a shell or missing
    final bool isEmpty =
        originalPost.isEmpty ||
        (author == null &&
            (originalPost['content'] == null ||
                originalPost['content'].isEmpty));

    final postText = originalPost['content'] ?? originalPost['post_text'] ?? '';

    final media = originalPost['media'] as List?;
    final postImage = (media != null && media.isNotEmpty)
        ? (media.first is String ? media.first : media.first['url'])
        : null;

    final String timestamp =
        (originalPost['time_ago'] ??
                originalPost['timeAgo'] ??
                originalPost['timestamp'] ??
                '')
            .toString();

    final Widget content =
        isDeleted ||
            (isPrivate && lacksPermission) ||
            isEmpty ||
            lacksPermission ||
            relationshipBroken
        ? _buildInaccessibleView(context, theme, authorId, authorName)
        : _buildNormalView(
            context,
            theme,
            authorId,
            authorName,
            authorAvatar,
            postText,
            postImage,
            timestamp,
          );

    return AbsorbPointer(absorbing: !isInteractive, child: content);
  }

  Widget _buildInaccessibleView(
    BuildContext context,
    ThemeData theme,
    String? authorId,
    String authorName,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.5),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lock Icon with circular background
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock,
                color: Colors.orangeAccent,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Content Unavailable",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
                          builder: (_) => PublicProfileScreen(userId: authorId),
                        ),
                      );
                    },
              child: Text(
                "Post by $authorName",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              originalPost['reason_text'] ??
                  "This content is no longer available.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalView(
    BuildContext context,
    ThemeData theme,
    String? authorId,
    String authorName,
    String? authorAvatar,
    String postText,
    String? postImage,
    String timestamp,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailScreen(post: originalPost),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.3),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            InkWell(
              onTap: authorId == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PublicProfileScreen(userId: authorId),
                        ),
                      );
                    },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                      backgroundImage: authorAvatar != null
                          ? NetworkImage(authorAvatar)
                          : null,
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
                    if (timestamp.isNotEmpty)
                      Text(
                        timestamp,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 
                            0.4,
                          ),
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Media
            if (postImage != null)
              AspectRatio(
                aspectRatio: 1.91, // Standard post aspect ratio
                child: Image.network(
                  postImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                    child: const Icon(Icons.broken_image, size: 20),
                  ),
                ),
              ),

            // Content
            if (postText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
    );
  }
}

