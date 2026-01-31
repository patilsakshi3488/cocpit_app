import 'dart:io';
import 'package:cocpit_app/services/cloudinary_service.dart';
import 'package:cocpit_app/services/story_service.dart';
import 'package:flutter/material.dart';

class StoryPreviewScreen extends StatefulWidget {
  final File storyFile;
  final bool isVideo;

  const StoryPreviewScreen({
    super.key,
    required this.storyFile,
    required this.isVideo,
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

      await StoryService.createStory(
        title: "",
        description: _captionController.text,
        mediaUrl: url,
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
    return Scaffold(
      backgroundColor: Colors.black, // Dark theme
      appBar: AppBar(
        title: const Text(
          "Preview Story",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor:
            Colors.grey[900], // Match header style slightly lighter
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
          // Content
          Positioned.fill(
            bottom: 160,
            child: widget.isVideo
                ? const Center(
                    child: Text(
                      "Video Preview",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : Image.file(widget.storyFile, fit: BoxFit.contain),
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
