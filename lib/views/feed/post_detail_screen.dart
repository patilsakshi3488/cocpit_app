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
    _post = _normalize(widget.post);
    // ⚡ PROACTIVE REFRESH: Shared posts might have stale stats or missing interaction IDs
    // We refresh immediately to ensure "likes/comments/three-dots" work correctly.
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshPost());
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> raw) {
    Map<String, dynamic> data = raw;
    if (raw.containsKey("post") && raw["post"] is Map) {
      data = Map<String, dynamic>.from(raw["post"]);
    } else if (raw.containsKey("data") && raw["data"] is Map) {
      data = Map<String, dynamic>.from(raw["data"]);
    } else {
      data = Map<String, dynamic>.from(raw);
    }

    // Reconstruction: If it's a shared post payload, map back to PostCard format
    if (!data.containsKey("author")) {
      final String? ownerId =
          data["post_owner_id"] ?? data["post_author_id"] ?? data["owner_id"];
      final String? ownerName =
          data["post_owner_name"] ??
          data["post_author_name"] ??
          data["owner_name"];
      final String? ownerAvatar =
          data["post_owner_avatar"] ?? data["owner_avatar"];

      if (ownerId != null || ownerName != null) {
        data["author"] = {
          "id": ownerId,
          "full_name": ownerName ?? "User",
          "avatar_url": ownerAvatar,
        };
      }
    }
    if (data.containsKey("post_text") && !data.containsKey("content")) {
      data["content"] = data["post_text"];
    }
    if ((data.containsKey("post_id") || data.containsKey("_id")) &&
        !data.containsKey("id")) {
      data["id"] = data["post_id"] ?? data["_id"];
    }

    return data;
  }

  Future<void> _refreshPost() async {
    final postId =
        _post["post_id"]?.toString() ??
        _post["id"]?.toString() ??
        _post["_id"]?.toString();
    if (postId == null) return;

    try {
      final response = await FeedApi.fetchSinglePost(postId);
      if (response != null && mounted) {
        // UNWRAP: Handle {post: {...}} or {data: {...}} or direct object
        Map<String, dynamic>? updated;
        if (response.containsKey("post")) {
          updated = response["post"];
        } else if (response.containsKey("data")) {
          updated = response["data"];
        } else {
          updated = response;
        }

        if (updated != null) {
          setState(() {
            _post = _normalize(updated!);
          });
        }
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
