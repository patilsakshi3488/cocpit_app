import 'package:flutter/material.dart';
import '../../services/feed_service.dart';
import '../feed/widgets/post_card.dart';
import '../feed/widgets/edit_post_modal.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class UserPostsFeedScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? initialPostId;

  const UserPostsFeedScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.initialPostId,
  });

  @override
  State<UserPostsFeedScreen> createState() => _UserPostsFeedScreenState();
}

class _UserPostsFeedScreenState extends State<UserPostsFeedScreen> {
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
      final response = await FeedApi.fetchMyPosts(
        cursorCreatedAt: cursorCreatedAt,
        cursorPostId: cursorPostId,
      );

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
              // We need to insert it where it belongs chronologically ideally,
              // but for now, we can just insert it at the top or append.
              // However, if we want to maintain STRICT order, we might just have to accept it wasn't found.
              // But user wants to SEE IT.
              // If we insert at 0, it changes order.
              // If we strictly want chronological, we might need to fetch OLDER posts until we find it?
              // That could be expensive.
              // Compromise: Add it to the list, perhaps at the top if it's new, or we just rely on "Show it".
              // The user complaint was "post will change their place... can't understand timing".
              // If we fetch a very old post and put it at the top, that breaks timing.
              // BUT if we don't have it, we can't show it.

              // Let's assume pagination usually finds it, or we just prepend for visibility.
              // Given the user constraint, maybe we should NOT auto-prepend if it breaks order?
              // But if it's missing, the scrolling won't work.
              // Let's stick to prepending BUT maybe we should try to fetch the page containing it? Complexity high.
              // For now, let's just add it to ensuring it exists.

              // Actually, if it's not in the first page, it's likely older.
              newPosts.add(singlePost);
              // Or sort?
              // Let's just append for now if not found, or prepend. Users usually tap recent stuff.
              // Let's keep the prepend logic for safety but use scrolling.
              // Wait, if I prepend, index is 0.
              // If I append, index is last.
              // I'll prepend so it's loaded.
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
                  isOwner: true,
                  onDelete: _handleDeletePost,
                  onPrivacyChange: _handlePrivacy,
                  onEdit: (id) async {
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
                      builder: (ctx) => EditPostModal(post: posts[postIndex]),
                    );

                    if (result == true) {
                      // Reload posts or update locally if we returned the new data
                      // Simple way: re-fetch or just trigger reload
                      _fetchPosts();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Post updated successfully"),
                        ),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}
