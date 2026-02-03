import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cocpit_app/models/story_model.dart';
import 'package:cocpit_app/services/story_service.dart';
import 'package:cocpit_app/services/secure_storage.dart';
import 'package:cocpit_app/widgets/time_ago_widget.dart';
import 'package:cocpit_app/views/profile/public_profile_screen.dart';

class StoryCommentsSheet extends StatefulWidget {
  final String storyId;
  final int initialCount;
  final bool isStoryAuthor;
  final Function(int count)? onCommentCountChanged;
  final bool embedInSheet;

  const StoryCommentsSheet({
    super.key,
    required this.storyId,
    this.initialCount = 0,
    required this.isStoryAuthor,
    this.onCommentCountChanged,
    this.embedInSheet = false,
  });

  @override
  State<StoryCommentsSheet> createState() => _StoryCommentsSheetState();
}

class _StoryCommentsSheetState extends State<StoryCommentsSheet> {
  List<StoryComment> _comments = [];
  bool _isLoading = true;
  String? _currentUserId;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _fetchCurrentUser();
    await _fetchComments();
  }

  Future<void> _fetchCurrentUser() async {
    final userJson = await AppSecureStorage.getUser();
    if (userJson != null) {
      final user = jsonDecode(userJson);
      setState(() {
        _currentUserId = user['id']?.toString() ?? user['_id']?.toString();
      });
    }
  }

  Future<void> _fetchComments() async {
    try {
      final comments = await StoryService.fetchComments(widget.storyId);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
        widget.onCommentCountChanged?.call(comments.length);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _postComment() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();
    _textController.clear();

    try {
      final newComment = await StoryService.postComment(widget.storyId, text);
      if (mounted) {
        setState(() {
          _comments.insert(0, newComment);
        });
        widget.onCommentCountChanged?.call(_comments.length);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to post comment")));
    }
  }

  Future<void> _toggleLike(StoryComment comment) async {
    final isLiked = comment.isLiked;
    setState(() {
      final index = _comments.indexOf(comment);
      if (index != -1) {
        _comments[index] = StoryComment(
          id: comment.id,
          storyId: comment.storyId,
          userId: comment.userId,
          content: comment.content,
          createdAt: comment.createdAt,
          likeCount: isLiked ? comment.likeCount - 1 : comment.likeCount + 1,
          isLiked: !isLiked,
          userAvatar: comment.userAvatar,
          userName: comment.userName,
        );
      }
    });

    try {
      await StoryService.likeComment(comment.id);
    } catch (e) {
      // Ignore revert for now
    }
  }

  void _showDeleteOptions(StoryComment comment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Manage Comment",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  "Delete Comment",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context); // Close sheet
                  _deleteComment(comment);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteComment(StoryComment comment) async {
    // Optimistic delete
    final int index = _comments.indexOf(comment);
    setState(() {
      _comments.remove(comment);
    });

    widget.onCommentCountChanged?.call(_comments.length);

    try {
      await StoryService.deleteComment(comment.id);
    } catch (e) {
      // Revert if failed
      if (mounted) {
        setState(() {
          if (index != -1 && index <= _comments.length) {
            _comments.insert(index, comment);
          } else {
            _comments.add(comment);
          }
        });
        widget.onCommentCountChanged?.call(_comments.length);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final colorScheme = theme.colorScheme;

    // Based on provided image design
    final sheetBg = Color(0xFF1E1E2C);
    final textColor = Colors.white;

    if (widget.embedInSheet) {
      return Column(
        children: [
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                ? Center(
                    child: Text(
                      "No comments yet.",
                      style: TextStyle(
                        color: Colors.white54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _comments.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final c = _comments[index];
                      return _buildCommentItem(c);
                    },
                  ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Add a comment...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white10,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _postComment,
                  icon: const Icon(Icons.send),
                  color: Colors.blueAccent,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white10,
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),
          ),

          // Added bottom padding for keyboard in embedded mode handled by parent mostly?
          // But input needs to be accessible. Since TabBarView usually expands, this is fine.
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Comments",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "${_comments.length}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 14,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white10),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                ? Center(
                    child: Text(
                      "No comments yet.",
                      style: TextStyle(
                        color: Colors.white54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _comments.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final c = _comments[index];
                      return _buildCommentItem(c);
                    },
                  ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Add a comment...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white10,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _postComment,
                  icon: const Icon(Icons.send),
                  color: Colors.blueAccent,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white10,
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(StoryComment c) {
    // Check if deletable: I am author of story || I am author of comment
    final bool canDelete =
        widget.isStoryAuthor ||
        (_currentUserId != null && c.userId == _currentUserId);

    return InkWell(
      onLongPress: canDelete ? () => _showDeleteOptions(c) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                if (c.userId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PublicProfileScreen(userId: c.userId),
                    ),
                  );
                }
              },
              child: CircleAvatar(
                backgroundImage: c.userAvatar != null
                    ? NetworkImage(c.userAvatar!)
                    : null,
                backgroundColor: Colors.white10,
                radius: 18,
                child: c.userAvatar == null
                    ? const Icon(Icons.person, color: Colors.white70)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (c.userId.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PublicProfileScreen(userId: c.userId),
                          ),
                        );
                      }
                    },
                    child: Row(
                      children: [
                        Text(
                          c.userName != null && c.userName!.isNotEmpty
                              ? c.userName!
                              : "User",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TimeAgoWidget(
                          dateTime: c.createdAt,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.content,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                GestureDetector(
                  onTap: () => _toggleLike(c),
                  child: Icon(
                    c.isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: c.isLiked ? Colors.redAccent : Colors.white54,
                  ),
                ),
                if (c.likeCount > 0)
                  Text(
                    "${c.likeCount}",
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
