import 'package:flutter/material.dart';
import '../../../services/feed_service.dart';
import '../../feed/widgets/post_card.dart';

class EditPostModal extends StatefulWidget {
  final Map<String, dynamic> post;

  const EditPostModal({super.key, required this.post});

  @override
  State<EditPostModal> createState() => _EditPostModalState();
}

class _EditPostModalState extends State<EditPostModal> {
  late TextEditingController _contentController;
  late bool _isPrivate;
  bool _isPreview = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(
      text: widget.post['content'] ?? '',
    );
    _isPrivate = widget.post['visibility'] == 'private';
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      final postId =
          widget.post["post_id"]?.toString() ?? widget.post["id"]?.toString();
      if (postId != null) {
        await FeedApi.updatePost(
          postId,
          content: _contentController.text,
          visibility: _isPrivate ? 'private' : 'public',
        );
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to update post: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor, // Or cardColor based on design
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40), // Balance close button
                Text(
                  "Edit Post",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Body
          Expanded(
            child: _isPreview ? _buildPreview(theme) : _buildEditForm(theme),
          ),

          const Divider(height: 1),
          // Footer
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!_isPreview)
                  TextButton.icon(
                    onPressed: () => setState(() => _isPreview = true),
                    icon: Icon(
                      Icons.visibility_outlined,
                      color: theme.primaryColor,
                      size: 20,
                    ),
                    label: Text(
                      "Preview",
                      style: TextStyle(color: theme.primaryColor),
                    ),
                  )
                else
                  TextButton(
                    onPressed: () => setState(() => _isPreview = false),
                    child: Text(
                      "Back to Edit",
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),

                Row(
                  children: [
                    if (!_isPreview && !isKeyboardVisible)
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF6B72FF,
                        ), // Violet/Blueish from screenshot
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Save",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(ThemeData theme) {
    final media = widget.post["media"] ?? widget.post["media_urls"] ?? [];
    String? mediaUrl;
    if (media.isNotEmpty) {
      final first = media.first;
      if (first is String) mediaUrl = first;
      if (first is Map) mediaUrl = first['url'];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Private Indicator
          GestureDetector(
            onTap: () => setState(() => _isPrivate = !_isPrivate),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2B2D31), // Dark button bg
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isPrivate ? Icons.visibility_off_outlined : Icons.public,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isPrivate ? "Private" : "Public",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // New container styling from screenshot
          if (mediaUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                mediaUrl,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: theme.cardColor, // Or a slightly lighter/darker shade
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _contentController,
              maxLines: 4,
              decoration: const InputDecoration.collapsed(
                hintText: "What's on your mind?",
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(ThemeData theme) {
    // Construct a preview post object
    final previewPost = Map<String, dynamic>.from(widget.post);
    previewPost['content'] = _contentController.text;
    previewPost['visibility'] = _isPrivate ? 'private' : 'public';
    // isOwner true for preview? Yes or no, doesn't matter much for visual

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostCard(
            post: previewPost,
            simpleView: false, // Show full card preview
            isOwner: true,
          ),
        ],
      ),
    );
  }
}
