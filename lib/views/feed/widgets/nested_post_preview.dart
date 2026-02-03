import 'package:flutter/material.dart';
import '../post_detail_screen.dart';

class NestedPostPreview extends StatelessWidget {
  final Map<String, dynamic> originalPost;

  const NestedPostPreview({super.key, required this.originalPost});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
    final authorData = originalPost['author'] ?? originalPost['user'] ?? {};
    final bool isFollowing =
        originalPost['is_following'] == true ||
        authorData['is_following'] == true;

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
        (originalPost['author'] == null &&
            (originalPost['content'] == null ||
                originalPost['content'].isEmpty));

    if (isDeleted ||
        (isPrivate && lacksPermission) ||
        isEmpty ||
        lacksPermission ||
        relationshipBroken) {
      final authorName =
          originalPost['author_name'] ??
          originalPost['author']?['full_name'] ??
          originalPost['author']?['name'] ??
          'Unknown User';

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.03),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lock Icon with circular background
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
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
              Text(
                "Post by $authorName",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                (isPrivate || isPersonal)
                    ? "This is a Personal post.\nConnect with the user to view it."
                    : "This content is no longer available.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.6),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // EXTRACT METADATA
    final authorName =
        originalPost['author_name'] ??
        originalPost['author']?['full_name'] ??
        originalPost['author']?['name'] ??
        'Unknown User';

    final authorAvatar =
        originalPost['author_avatar'] ??
        originalPost['author']?['avatar_url'] ??
        originalPost['author']?['avatar'];

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
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.01),
          border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundImage: authorAvatar != null
                        ? NetworkImage(authorAvatar)
                        : null,
                    child: authorAvatar == null
                        ? Text(
                            authorName.isNotEmpty ? authorName[0] : '?',
                            style: const TextStyle(fontSize: 10),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            authorName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "• Reposted",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (timestamp.isNotEmpty)
                    Text(
                      timestamp,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                ],
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
                    color: theme.dividerColor.withOpacity(0.1),
                    child: const Icon(Icons.broken_image, size: 20),
                  ),
                ),
              ),

            // Content
            if (postText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  postText,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
