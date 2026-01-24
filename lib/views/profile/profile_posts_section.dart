import 'package:flutter/material.dart';
import '../../views/profile/widgets/profile_post_summary_widget.dart';
import '../../views/profile/user_posts_feed_screen.dart';

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

    // Limit to latest 4 for the grid
    final displayPosts = posts.take(4).toList();

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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserPostsFeedScreen(
                        userId: "me", // Or actual ID if available
                        userName: userName,
                      ),
                    ),
                  );
                },
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

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85, // Taller cards
            ),
            itemCount: displayPosts.length,
            itemBuilder: (context, index) {
              final post = displayPosts[index];
              return ProfilePostSummaryWidget(
                post: post,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserPostsFeedScreen(
                        userId: "me",
                        userName: userName,
                        initialPostId:
                            post["post_id"]?.toString() ??
                            post["id"]?.toString(),
                      ),
                    ),
                  );
                },
                onDelete: onDeletePost,
                onEdit: onEditPost,
                onTogglePrivacy: onTogglePrivacy,
              );
            },
          ),
        ],
      ),
    );
  }
}
