import 'package:flutter/material.dart';
import '../post_detail_screen.dart';
import '../../profile/public_profile_screen.dart';

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

    // EXTRACT METADATA (Support both rich payload and nested legacy structure)
    // Rich payload fields: post_owner_name, post_image, post_text, etc.
    final authorName =
        sharedPost['post_owner_name'] ??
        sharedPost['author']?['full_name'] ??
        sharedPost['author']?['name'] ??
        'Unknown User';

    final authorAvatar =
        sharedPost['post_owner_avatar'] ?? sharedPost['author']?['avatar_url'];

    final authorId =
        (sharedPost['post_owner_id'] ??
                sharedPost['post_author_id'] ??
                sharedPost['owner_id'] ??
                sharedPost['author']?['id'] ??
                sharedPost['author']?['_id'] ??
                sharedPost['user']?['id'] ??
                sharedPost['user']?['_id'] ??
                sharedPost['user_id'])
            ?.toString();

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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2735), // Sleek deep dark bubble color
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1️⃣ HEADER: Author Info (Target: Profile)
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
              color: Colors.white.withOpacity(0.03),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundImage: authorAvatar != null
                        ? NetworkImage(authorAvatar)
                        : null,
                    backgroundColor: theme.primaryColor.withOpacity(0.2),
                    child: authorAvatar == null
                        ? Text(
                            authorName.isNotEmpty ? authorName[0] : '?',
                            style: const TextStyle(fontSize: 10),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        Text(
                          "Shared a post",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2️⃣ BODY: Media & Caption (Target: Post Detail)
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
                            color: Colors.black.withOpacity(0.5),
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
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),

          // 3️⃣ FOOTER / MESSAGE (Optional message sent with post)
          if (messageText != null && messageText!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
                color: Colors.white.withOpacity(0.01),
              ),
              child: Text(
                messageText!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // 4️⃣ VIEW DETAILS CTA
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.05)),
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
    );
  }
}
