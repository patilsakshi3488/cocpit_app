import 'package:flutter/material.dart';
import '../../services/feed_service.dart';
import '../feed/widgets/post_card.dart';
import '../feed/widgets/edit_post_modal.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class UserPostsFeedScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? initialPostId;
  final bool isOwner;

  const UserPostsFeedScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.initialPostId,
    this.isOwner = false,
  });

  @override
  State<UserPostsFeedScreen> createState() => _UserPostsFeedScreenState();
}

class _UserPostsFeedScreenState extends State<UserPostsFeedScreen> {
  // ... (existing state vars)
  List<Map<String, dynamic>> posts = [];
  bool isLoading = true;
  String? cursorCreatedAt;
  String? cursorPostId;
  bool hasMore = true;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    if (!hasMore && cursorCreatedAt != null) return;

    try {
      final Map<String, dynamic> response;
      if (widget.userId == 'me') {
        response = await FeedApi.fetchMyPosts(
          cursorCreatedAt: cursorCreatedAt,
          cursorPostId: cursorPostId,
        );
      } else {
        response = await FeedApi.fetchUserPosts(
          userId: widget.userId,
          cursorCreatedAt: cursorCreatedAt,
          cursorPostId: cursorPostId,
        );
      }

      final List<Map<String, dynamic>> newPosts = [];
      if (response['posts'] != null) {
        newPosts.addAll(List<Map<String, dynamic>>.from(response['posts']));
      } else if (response['data'] != null) {
        newPosts.addAll(List<Map<String, dynamic>>.from(response['data']));
      }

      // Check if we need to fetch the initial post specifically
      if (posts.isEmpty && widget.initialPostId != null) {
        final foundInBatch = newPosts.any(
          (p) =>
              p['post_id']?.toString() == widget.initialPostId ||
              p['id']?.toString() == widget.initialPostId,
        );

        if (!foundInBatch) {
          try {
            final singlePost = await FeedApi.fetchSinglePost(
              widget.initialPostId!,
            );
            if (singlePost != null) {
              newPosts.insert(0, singlePost);
            }
          } catch (e) {
            debugPrint("Could not fetch initial post: $e");
          }
        }
      }

      if (mounted) {
        setState(() {
          posts.addAll(newPosts);
          isLoading = false;

          final nextCursor = response["nextCursor"];
          if (nextCursor == null) {
            hasMore = false;
          } else {
            cursorCreatedAt = nextCursor["cursorCreatedAt"];
            cursorPostId = nextCursor["cursorPostId"];
          }
        });

        // Scroll to initial post if first load
        if (widget.initialPostId != null && posts.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToInitialPost();
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _scrollToInitialPost() {
    if (widget.initialPostId == null) return;

    final index = posts.indexWhere(
      (p) =>
          p['post_id']?.toString() == widget.initialPostId ||
          p['id']?.toString() == widget.initialPostId,
    );

    if (index != -1) {
      _itemScrollController.jumpTo(index: index);
    }
  }

  Future<void> _handleDeletePost(String postId) async {
    // Prevent delete if not owner
    if (!widget.isOwner) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text("Are you sure you want to delete this post?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FeedApi.deletePost(postId);
        setState(() {
          posts.removeWhere(
            (p) =>
                p['post_id']?.toString() == postId ||
                p['id']?.toString() == postId,
          );
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Post deleted")));
        }
      } catch (_) {}
    }
  }

  Future<void> _handlePrivacy(String postId, bool isPrivate) async {
    if (!widget.isOwner) return;
    try {
      await FeedApi.setPostVisibility(postId, isPrivate);
      setState(() {
        final index = posts.indexWhere(
          (p) =>
              p['post_id']?.toString() == postId ||
              p['id']?.toString() == postId,
        );
        if (index != -1) {
          posts[index]['visibility'] = isPrivate ? 'private' : 'public';
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.userName}'s Posts")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ScrollablePositionedList.builder(
              itemScrollController: _itemScrollController,
              itemPositionsListener: _itemPositionsListener,
              itemCount: posts.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == posts.length) {
                  _fetchPosts();
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return PostCard(
                  post: posts[index],
                  simpleView: true,
                  isOwner: widget.isOwner, // ✅ Pass correct owner flag
                  onDelete: widget.isOwner ? _handleDeletePost : null,
                  onPrivacyChange: widget.isOwner ? _handlePrivacy : null,
                  onEdit: widget.isOwner
                      ? (id) async {
                          // Find actual post object
                          final postIndex = posts.indexWhere(
                            (p) =>
                                p['post_id']?.toString() == id ||
                                p['id']?.toString() == id,
                          );
                          if (postIndex == -1) return;

                          final result = await showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) =>
                                EditPostModal(post: posts[postIndex]),
                          );

                          if (result == true) {
                            _fetchPosts();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Post updated successfully"),
                              ),
                            );
                          }
                        }
                      : null,
                );
              },
            ),
    );
  }
}
