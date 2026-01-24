import 'package:flutter/material.dart';
import 'widgets/post_card.dart';
import '../../services/feed_service.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Map<String, dynamic> _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  Future<void> _refreshPost() async {
    final postId = _post["post_id"]?.toString() ?? _post["id"]?.toString();
    if (postId == null) return;

    try {
      final updated = await FeedApi.fetchSinglePost(postId);
      if (updated != null && mounted) {
        setState(() {
          _post = updated;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post")),
      body: RefreshIndicator(
        onRefresh: _refreshPost,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: PostCard(
            post: _post,
            simpleView: true,
            // We can add callbacks here if needed, but PostCard handles likes/comments internally mostly
            // For delete/edit, we rely on the same logic if we pass callbacks
          ),
        ),
      ),
    );
  }
}
