import 'package:flutter/material.dart';
import '../../views/feed/widgets/post_card.dart';

class ProfileLatestPostsSection extends StatelessWidget {
  final List<Map<String, dynamic>> posts;
  final String userName;
  final VoidCallback onSeeAllPosts;
  final Function(String) onDeletePost;
  final Function(String) onEditPost;
  final Function(String, bool) onTogglePrivacy;

  const ProfileLatestPostsSection({
    super.key,
    required this.posts,
    required this.userName,
    required this.onSeeAllPosts,
    required this.onDeletePost,
    required this.onEditPost,
    required this.onTogglePrivacy,
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) return const SizedBox();

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Latest Posts",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onSeeAllPosts,
                child: Text(
                  "See all posts",
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Use the standardized PostCard
          ...posts
              .take(3)
              .map(
                (post) => PostCard(
                  post: post,
                  isOwner: true,
                  onDelete: onDeletePost,
                  onEdit: onEditPost,
                  onPrivacyChange: onTogglePrivacy,
                ),
              ),
        ],
      ),
    );
  }
}
