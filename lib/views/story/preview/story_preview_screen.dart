import 'dart:io';
import 'package:cocpit_app/models/story_model.dart';
import 'package:cocpit_app/services/cloudinary_service.dart';
import 'package:cocpit_app/services/story_service.dart';
import 'package:cocpit_app/utils/story_upload_mapper.dart';
import 'package:cocpit_app/views/story/story_renderer.dart';
import 'package:cocpit_app/views/story/editor/story_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

class StoryPreviewScreen extends StatefulWidget {
  final File storyFile;
  final bool isVideo;
  final bool isSimple; // âœ… NEW: Skip editor logic
  final Map<String, dynamic>? storyMetadata;
  final List<TextLayer>? originalLayers; // âœ… Added for re-edit
  final Color? originalBackgroundColor; // âœ… Added for re-edit

  const StoryPreviewScreen({
    super.key,
    required this.storyFile,
    required this.isVideo,
    this.isSimple = false,
    this.storyMetadata,
    this.originalLayers,
    this.originalBackgroundColor,
  });

  @override
  State<StoryPreviewScreen> createState() => _StoryPreviewScreenState();
}

class _StoryPreviewScreenState extends State<StoryPreviewScreen> {
  final TextEditingController _captionController = TextEditingController();
  final ScreenshotController _screenshotController =
      ScreenshotController(); // âœ… ADDED
  bool _isUploading = false;

  Future<void> _uploadStory() async {
    if (_isUploading) return;
    setState(() => _isUploading = true);

    try {
      String mediaUrl = "";
      String? publicId;

      // âœ… Website Rule: Upload clean source media, NOT baked compositions.
      // Compositions are handled live via metadata layers.
      final uploadResult = await CloudinaryService.uploadFile(
        widget.storyFile,
        isVideo: widget.isVideo,
      );
      mediaUrl = uploadResult['url'];
      publicId = uploadResult['public_id'];

      // âœ… 3. BUILD PAYLOAD (Web-Compatible)
      final payload = StoryUploadMapper.buildPayload(
        cloudinaryUrl: mediaUrl,
        mediaType: widget.isVideo ? 'video' : 'image',
        publicId: publicId,
        description: _captionController.text,
        editorMetadata: widget.isSimple
            ? null
            : {
                "layers": widget.storyMetadata?['layers'],
                "background": widget.storyMetadata?['background'],
              },
      );

      await StoryService.createStory(payload);

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
            onPressed: () => _handleEdit(context), // âœ… Improved Re-edit
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
            child: Screenshot(
              controller: _screenshotController,
              child: StoryRenderer(
                story: previewStory,
                previewFile: widget.storyFile,
                isPreview: true, // âœ… Required for safety net
              ),
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
                  colors: [Colors.black, Colors.black.withValues(alpha: 0.0)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Caption
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 
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
                              _handleEdit(context), // âœ… Improved Re-edit
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

  void _handleEdit(BuildContext context) {
    // âœ… If simple, we navigate FORWARD to the editor instead of just popping.
    // This allows transitioning from a direct pick to a rich editor session.
    if (widget.isSimple) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StoryEditorScreen(
            initialFile: widget.storyFile,
            isVideo: widget.isVideo,
          ),
        ),
      );
      return;
    }

    // âœ… Cleanly return to editor with raw state
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => StoryEditorScreen(
          initialFile: widget.storyFile, // Pass the file back
          isVideo: widget.isVideo,
          initialBackgroundColor: widget.originalBackgroundColor,
          initialTextLayers: widget.originalLayers,
        ),
      ),
    );
  }
}

