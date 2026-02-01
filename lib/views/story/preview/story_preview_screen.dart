import 'dart:io';
import 'package:cocpit_app/models/story_model.dart';
import 'package:cocpit_app/services/cloudinary_service.dart';
import 'package:cocpit_app/services/story_service.dart';
import 'package:cocpit_app/views/story/story_renderer.dart';
import 'package:flutter/material.dart';

class StoryPreviewScreen extends StatefulWidget {
  final File storyFile;
  final bool isVideo;
  final Map<String, dynamic>? storyMetadata;

  const StoryPreviewScreen({
    super.key,
    required this.storyFile,
    required this.isVideo,
    this.storyMetadata,
  });

  @override
  State<StoryPreviewScreen> createState() => _StoryPreviewScreenState();
}

class _StoryPreviewScreenState extends State<StoryPreviewScreen> {
  final TextEditingController _captionController = TextEditingController();
  bool _isUploading = false;

  Future<void> _uploadStory() async {
    if (_isUploading) return;
    setState(() => _isUploading = true);

    try {
      final url = await CloudinaryService.uploadFile(
        widget.storyFile,
        isVideo: widget.isVideo,
      );

      // NOTE: With Flattened Architecture, we no longer need to strictly inject "main-image" src
      // because the mediaUrl itself IS the flattened image which the website uses.
      // However, we still pass metadata for App interactions.

      await StoryService.createStory(
        title: "",
        description: _captionController.text,
        mediaUrl: url,
        storyMetadata: widget.storyMetadata,
      );

      if (mounted) {
        // Pop all the way back home
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Construct a temporary Story object for rendering
    final previewStory = Story(
      storyId: "preview",
      mediaUrl: "", // Not used when previewFile is provided
      mediaType: widget.isVideo ? 'video' : 'image',
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      isAuthor: true,
      hasViewed: false,
      hasLiked: false,
      viewCount: 0,
      likeCount: 0,
      commentCount: 0,
      storyMetadata: widget.storyMetadata,
    );

    return Scaffold(
      backgroundColor: Colors.black, // Dark theme
      appBar: AppBar(
        title: const Text(
          "Preview Story",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.grey[900],
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Go back to Editor
            child: const Text(
              "Edit",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Content using StoryRenderer for accurate preview
          Positioned.fill(
            bottom: 160,
            child: StoryRenderer(
              story: previewStory,
              previewFile: widget.storyFile,
              // Note: Video preview might need a controller if we want it to play.
              // For now, if it's video, StoryRenderer might show loader if we don't pass controller.
              // However, StoryEditor usually passes a file.
              // If isVideo is true, we should ideally pass a video controller.
              // But StoryPreview doesn't init one currently.
              // Let's rely on basic image preview for now or let StoryRenderer handle file video if we implement it.
              // Since StoryRenderer with file supports Image.file, it works for image.
              // For Video, StoryRenderer expects VideoPlayerController.
              // If we don't pass one, it shows loader.
              // I'll leave video as is in original for now?
              // The original used Image.file for image and Text "Video Preview" for video.
              // I'll stick to StoryRenderer for Image and fallback for Video if needed.
            ),
          ),

          if (widget.isVideo)
            const Center(
              child: Text(
                "Video Preview (No Playback)",
                style: TextStyle(color: Colors.white),
              ),
            ),

          // Bottom Controls
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black, Colors.black.withOpacity(0.0)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Caption
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(
                        0.2,
                      ), // Glassmorphism caption
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _captionController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      minLines: 1,
                      decoration: const InputDecoration(
                        hintText: "Add a caption...",
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons Row
                  Row(
                    children: [
                      // Edit Button (Grey)
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.pop(context), // Go back to editor
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            "Edit",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Upload Button (Blue)
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : _uploadStory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isUploading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Upload Story",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16), // Bottom safety
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
