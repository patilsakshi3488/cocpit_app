import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:cocpit_app/services/feed_service.dart';
import 'package:cocpit_app/services/story_service.dart';
import 'editor/draggable_resizable_widget.dart';

class ShareToStoryScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const ShareToStoryScreen({super.key, required this.post});

  @override
  State<ShareToStoryScreen> createState() => _ShareToStoryScreenState();
}

class _ShareToStoryScreenState extends State<ShareToStoryScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final TextEditingController _descriptionController = TextEditingController();

  // Background Options
  final List<Color> _colors = [
    Colors.black,
    Colors.purple,
    Colors.teal,
    Colors.orange,
    Colors.blueGrey,
  ];

  final List<Gradient> _gradients = [
    const LinearGradient(
      colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFF00c6ff), Color(0xFF0072ff)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFFf12711), Color(0xFFf5af19)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFF1c92d2), Color(0xFFf2fcfe)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  int _selectedBgIndex = 0;
  bool _isGradient = true; // Start with gradient
  double _scale = 1.0;
  bool _isSharing = false;

  List<Widget> _textOverlays = [];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _addText() async {
    String? text = await showDialog<String>(
      context: context,
      builder: (context) {
        String value = "";
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text("Add Text", style: TextStyle(color: Colors.white)),
          content: TextField(
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Type something...",
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
            onChanged: (v) => value = v,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, value),
              child: const Text("Done"),
            ),
          ],
        );
      },
    );

    if (text != null && text.isNotEmpty) {
      setState(() {
        _textOverlays.add(
          DraggableResizableWidget(
            key: UniqueKey(),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ),
        );
      });
    }
  }

  Future<void> _createStory() async {
    setState(() => _isSharing = true);

    try {
      // 1. Capture Image
      final Uint8List? imageBytes = await _screenshotController.capture();
      if (imageBytes == null) throw Exception("Failed to capture image");

      // 2. Save to Temp File
      final tempDir = Directory.systemTemp;
      final file = await File(
        '${tempDir.path}/story_share_${DateTime.now().millisecondsSinceEpoch}.png',
      ).create();
      await file.writeAsBytes(imageBytes);

      // 3. Upload Media
      final uploadedMedia = await FeedApi.uploadMedia([file]);
      if (uploadedMedia.isEmpty) throw Exception("Failed to upload media");

      final mediaUrl = uploadedMedia.first['url'];

      // Get Post ID for deep linking
      final postId =
          widget.post["_id"]?.toString() ??
          widget.post["post_id"]?.toString() ??
          widget.post["id"]?.toString() ??
          "";

      // 4. Create Story with clean metadata approach
      await StoryService.createStory(
        title: null, // Title is not used for linking anymore
        description: _descriptionController.text.trim(),
        mediaUrl: mediaUrl,
        storyMetadata: {"linked_post_id": postId, "source": "feed_share"},
      );

      if (mounted) {
        Navigator.pop(context); // Close Screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Shared to story successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Share to story failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to share: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Add to Story"),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // --------------------------
          // PREVIEW AREA
          // --------------------------
          Expanded(
            child: Center(
              child: Screenshot(
                controller: _screenshotController,
                child: SafeArea(
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(
                      context,
                    ).size.height, // Full screen height
                    decoration: BoxDecoration(
                      color: _isGradient ? null : _colors[_selectedBgIndex],
                      gradient: _isGradient
                          ? _gradients[_selectedBgIndex]
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Transform.scale(
                            scale: MediaQuery.of(context).size.height < 700
                                ? 0.9
                                : _scale,
                            child: _buildPostCard(),
                          ),
                        ),
                        ..._textOverlays,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          //Controls
          Container(
            color: Colors.black,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add Text Button
                Center(
                  child: TextButton.icon(
                    onPressed: _addText,
                    icon: const Icon(Icons.text_fields, color: Colors.white),
                    label: const Text(
                      "Add Text Overlay",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white10,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Background Selector
                const Text(
                  "Story Background",
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _gradients.length + _colors.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final isGrad = index < _gradients.length;
                      final realIndex = isGrad
                          ? index
                          : index - _gradients.length;
                      final isSelected =
                          _isGradient == isGrad &&
                          _selectedBgIndex == realIndex;

                      return GestureDetector(
                        onTap: () => setState(() {
                          _isGradient = isGrad;
                          _selectedBgIndex = realIndex;
                        }),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isGrad ? null : _colors[realIndex],
                            gradient: isGrad ? _gradients[realIndex] : null,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Post Size Slider
                Row(
                  children: [
                    const Text(
                      "Post Size",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const Spacer(),
                    Text(
                      "${(_scale * 100).toInt()}%",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                Slider(
                  value: _scale,
                  min: 0.5,
                  max: 1.2,
                  activeColor: Colors.blueAccent,
                  inactiveColor: Colors.white24,
                  onChanged: (val) => setState(() => _scale = val),
                ),

                // Description
                TextField(
                  controller: _descriptionController,
                  maxLines: 2,
                  maxLength: 120,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.description,
                      color: Colors.white54,
                    ),
                    hintText: "Add a description to your story...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSharing ? null : _createStory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSharing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text("Create Story"),
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

  Widget _buildPostCard() {
    // ----------------------------------------------------
    // ROBUST AUTHOR EXTRACTION
    // ----------------------------------------------------
    final author =
        widget.post['author'] ??
        widget.post['user'] ??
        widget.post['owner'] ??
        widget.post['creator'] ??
        {};

    // Name
    final authorName =
        author['name'] ??
        author['full_name'] ??
        author['username'] ??
        author['user_name'] ??
        widget.post['author_name'] ?? // Flattened
        widget.post['user_name'] ??
        "Unknown User";

    // Avatar
    final authorAvatar =
        author['avatar'] ??
        author['avatar_url'] ??
        author['profile_picture'] ??
        widget.post['author_avatar'] ?? // Flattened
        widget.post['user_avatar'];

    // Media
    final media = widget.post['media'] ?? widget.post['media_urls'] ?? [];
    String? imageUrl;
    if (media is List && media.isNotEmpty) {
      if (media.first is String)
        imageUrl = media.first;
      else if (media.first is Map)
        imageUrl = media.first['url'];
    }

    return Container(
      width: 320, // Slightly wider
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C), // Dark Card
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Row
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: authorAvatar != null
                    ? NetworkImage(authorAvatar)
                    : null,
                backgroundColor: Colors.white10,
                child: authorAvatar == null
                    ? Text(
                        authorName.isNotEmpty
                            ? authorName[0].toUpperCase()
                            : "?",
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  authorName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Image / Content - ConstrainedBox (Fix 1)
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 280, // SAFE LIMIT
            ),
            child: imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 150,
                        color: Colors.grey[800],
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  )
                : Text(
                    widget.post['content'] ?? widget.post['text'] ?? "",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),

          const SizedBox(height: 12),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Tap to view post",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Icon(Icons.arrow_forward, color: Colors.white54, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}
