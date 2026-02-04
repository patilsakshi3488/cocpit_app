import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/share_service.dart';
import '../../story/share_to_story_screen.dart';
import '../../post/create_post_screen.dart';

class ShareSheet extends StatefulWidget {
  final Map<String, dynamic> post;

  const ShareSheet({super.key, required this.post});

  @override
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet> {
  final ShareService _shareService = ShareService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  List<Map<String, dynamic>> _allTargets = [];
  List<Map<String, dynamic>> _filteredTargets = [];
  final Set<String> _selectedUserIds = {};
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadTargets();
  }

  Future<void> _loadTargets() async {
    final targets = await _shareService.getShareTargets();
    if (mounted) {
      setState(() {
        _allTargets = targets;
        _filteredTargets = targets;
        _isLoading = false;
      });
    }
  }

  void _filterTargets(String query) {
    setState(() {
      _filteredTargets = _allTargets
          .where(
            (t) =>
                (t['name'] ?? '').toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  Future<void> _handleShare() async {
    if (_selectedUserIds.isEmpty) return;

    setState(() => _isSending = true);

    final String postId =
        widget.post["_id"]?.toString() ??
        widget.post["post_id"]?.toString() ??
        widget.post["id"]?.toString() ??
        "";

    final author = widget.post["author"] ?? widget.post["user"] ?? {};
    final media = widget.post["media"] ?? widget.post["media_urls"] ?? [];
    String? postImage;
    if (media is List && media.isNotEmpty) {
      final first = media.first;
      postImage = first is String ? first : first["url"];
    }

    // Standardised payload mapping matching the PROMPT and real app expectations
    final sharedPostData = {
      "post_id": postId,
      "post_owner_id": author["_id"] ?? author["id"] ?? "",
      "post_owner_name": author["full_name"] ?? author["name"] ?? "User",
      "post_owner_avatar": author["avatar_url"] ?? author["avatar"],
      "post_image": postImage,
      "post_text": widget.post["content"] ?? widget.post["text"] ?? "",
      "post_type":
          widget.post["post_type"] ??
          (widget.post["poll"] != null ? "poll" : "text"),
      "media": media,
      "poll": widget.post["poll"],
      "created_at": widget.post["created_at"],
    };

    final success = await _shareService.shareToUsers(
      postId: postId,
      userIds: _selectedUserIds.toList(),
      message: _messageController.text.trim().isEmpty
          ? null
          : _messageController.text.trim(),
      sharedPostData: sharedPostData,
    );

    if (mounted) {
      setState(() => _isSending = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? "Post shared successfully" : "Some shares failed",
          ),
          backgroundColor: success ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Share Post",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _selectedUserIds.isEmpty || _isSending
                      ? null
                      : _handleShare,
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Send"),
                ),
              ],
            ),
          ),

          // Options Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _optionButton(
                  icon: Icons.repeat,
                  label: "Share to Feed",
                  onTap: () async {
                    final result = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) =>
                          CreatePostScreen(sharedPost: widget.post),
                    );
                    if (mounted && result == true) {
                      Navigator.pop(
                        context,
                        true,
                      ); // Close share sheet with success
                    }
                  },
                ),
                const SizedBox(width: 16),
                _optionButton(
                  icon: Icons.add_circle_outline,
                  label: "Share to Story",
                  onTap: () async {
                    // Navigate to ShareToStoryScreen
                    final result = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) =>
                          ShareToStoryScreen(post: widget.post),
                    );
                    if (mounted && result == true) {
                      Navigator.pop(context); // Close share sheet
                    }
                  },
                ),
                const SizedBox(width: 16),
                _optionButton(
                  icon: Icons.link,
                  label: "Copy Link",
                  onTap: () {
                    final String postId =
                        widget.post["_id"]?.toString() ??
                        widget.post["post_id"]?.toString() ??
                        widget.post["id"]?.toString() ??
                        "";
                    Clipboard.setData(
                      ClipboardData(text: "https://example.com/post/$postId"),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Link copied to clipboard")),
                    );
                  },
                ),
              ],
            ),
          ),

          const Divider(),

          // Quick Message
          if (_selectedUserIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "Add a message...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ),

          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterTargets,
              decoration: InputDecoration(
                hintText: "Search people...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colorScheme.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          // Targeted users list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTargets.isEmpty
                ? const Center(child: Text("No users found"))
                : ListView.builder(
                    itemCount: _filteredTargets.length,
                    itemBuilder: (context, index) {
                      final user = _filteredTargets[index];
                      final id = user['id'];
                      final isSelected = _selectedUserIds.contains(id);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user['avatar'] != null
                              ? NetworkImage(user['avatar'])
                              : null,
                          child: user['avatar'] == null
                              ? Text(user['name'][0])
                              : null,
                        ),
                        title: Text(user['name'] ?? 'Unknown'),
                        subtitle: Text(user['headline'] ?? '', maxLines: 1),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedUserIds.add(id);
                              } else {
                                _selectedUserIds.remove(id);
                              }
                            });
                          },
                          shape: const CircleBorder(),
                        ),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedUserIds.remove(id);
                            } else {
                              _selectedUserIds.add(id);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _optionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon),
          ),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
