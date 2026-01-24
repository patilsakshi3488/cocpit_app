import 'package:flutter/material.dart';

class ProfilePostSummaryWidget extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onTap;
  final Function(String) onDelete;
  final Function(String) onEdit;
  final Function(String, bool) onTogglePrivacy;

  const ProfilePostSummaryWidget({
    super.key,
    required this.post,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
    required this.onTogglePrivacy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String postId =
        post["post_id"]?.toString() ?? post["id"]?.toString() ?? "";
    final String content = post["content"] ?? "";
    final List media = post["media"] ?? post["media_urls"] ?? [];
    final bool isPrivate = post['visibility'] == 'private';

    final bool isPoll =
        (post['post_type']?.toString().toLowerCase() == 'poll') ||
        (post['type']?.toString().toLowerCase() == 'poll') ||
        post['poll_data'] != null ||
        post['poll_id'] != null ||
        post['poll_options'] != null ||
        post['options'] != null;

    // Determine background image
    String? bgImage;
    if (media.isNotEmpty) {
      final first = media.first;
      if (first is String) {
        bgImage = first;
      } else if (first is Map) {
        bgImage = first['url'];
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isPoll ? const Color(0xFF2B2D31) : theme.cardColor,
          gradient: isPoll
              ? const LinearGradient(
                  colors: [
                    Color(0xFF6B72FF),
                    Color(0xFFD670FF),
                  ], // Violet gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          image: bgImage != null
              ? DecorationImage(
                  image: NetworkImage(bgImage),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.3),
                    BlendMode.darken,
                  ),
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (bgImage == null) // Show text prominently if no image
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isPoll)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8.0),
                                child: Icon(
                                  Icons.poll,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            Text(
                              content,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: isPoll ? Colors.white : null,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (bgImage != null && content.isNotEmpty)
                    Text(
                      content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // 3-Dots Menu
            Positioned(
              top: 4,
              right: 4,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: Colors.white),
                onSelected: (value) {
                  if (value == 'edit') onEdit(postId);
                  if (value == 'privacy') onTogglePrivacy(postId, !isPrivate);
                  if (value == 'delete') onDelete(postId);
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
              ),
            ),

            // Privacy Indicator
            if (isPrivate)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock, color: Colors.white, size: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
