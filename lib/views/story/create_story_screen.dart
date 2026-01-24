import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:cocpit_app/services/cloudinary_service.dart';
import 'package:cocpit_app/services/story_service.dart';
// import 'package:video_trimmer/video_trimmer.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final _picker = ImagePicker();
  // final Trimmer _trimmer = Trimmer();
  File? _file;
  bool _isVideo = false;
  VideoPlayerController? _videoController;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  bool _isUploading = false;

  Future<void> _pickMedia(bool video) async {
    final XFile? picked = video
        ? await _picker.pickVideo(source: ImageSource.gallery)
        : await _picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    setState(() {
      _file = File(picked.path);
      _isVideo = video;
    });

    if (video) {
      _videoController?.dispose();

      _videoController = VideoPlayerController.file(_file!)
        ..initialize().then((_) {
          final duration = _videoController!.value.duration;

          // ⛔ enforce 30 sec limit AFTER init
          if (duration.inSeconds > 35) {
            _videoController?.dispose();
            _videoController = null;

            setState(() {
              _file = null;
              _isVideo = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Video must be 30 seconds or less"),
              ),
            );
            return;
          }

          setState(() {}); // valid video → show preview
        });
    }
  }

  Future<void> _submit() async {
    if (_file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add image or video")),
      );
      return;
    }
    setState(() => _isUploading = true);

    try {
      final url = await CloudinaryService.uploadFile(_file!, isVideo: _isVideo);
      final String typeToSend = _isVideo ? "video" : "image";

      await StoryService.createStory(
        title: _titleController.text,
        description: _descController.text,
        mediaUrl: url,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true to refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Create Story",
          style: theme.textTheme.titleLarge,
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actions: [
          if (_file != null && !_isUploading)
            IconButton(
              onPressed: _submit,
              icon: Icon(Icons.check, color: colorScheme.primary),
            ),
        ],
      ),
      body: _isUploading
          ? Center(
        child: CircularProgressIndicator(
          color: colorScheme.primary,
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ======================
            // MEDIA PREVIEW
            // ======================
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: _file == null
                  ? Center(

                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 64,
                  color: colorScheme.onSurface.withOpacity(0.4),
                ),
              )
                  : _isVideo
                  ? (_videoController != null &&
                  _videoController!.value.isInitialized
                  ? GestureDetector(
                onTap: () {
                  setState(() {
                    if (_videoController!.value.isPlaying) {
                      _videoController!.pause();
                    } else {
                      _videoController!.play();
                    }
                  });
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio:
                      _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                    if (!_videoController!.value.isPlaying)
                      Icon(
                        Icons.play_circle_fill,
                        size: 64,
                        color: Colors.white.withOpacity(0.8),
                      ),
                  ],
                ),
              )
                  : Center(
                child: CircularProgressIndicator(
                  color: colorScheme.primary,
                ),
              )
              )
                  : Image.file(
                _file!,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),

            const SizedBox(height: 16),

            // ======================
            // PICKER BUTTONS
            // ======================
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickMedia(false),
                    icon: const Icon(Icons.image),
                    label: const Text("Image"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickMedia(true),
                    icon: const Icon(Icons.videocam),
                    label: const Text("Video"),
                  ),
                ),
              ],
            ),

            // if (_file != null) ...[
              const SizedBox(height: 24),

              // ======================
              // TITLE
              // ======================
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Title",
                ),
              ),

              const SizedBox(height: 12),

              // ======================
              // CAPTION
              // ======================
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Caption (Optional)",
                ),
              ),

              const SizedBox(height: 24),

              // ======================
              // REMOVE MEDIA
              // ======================
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _file = null;
                    _videoController?.dispose();
                    _videoController = null;
                    _isVideo = false;
                  });
                },
                icon: Icon(Icons.delete, color: colorScheme.error),
                label: Text(
                  "Remove Media",
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            // ],
          ],
        ),

      ),
    );
  }

}




