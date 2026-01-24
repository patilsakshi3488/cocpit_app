import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoStoryThumbnail extends StatefulWidget {
  final String mediaUrl;

  const VideoStoryThumbnail({super.key, required this.mediaUrl});

  @override
  State<VideoStoryThumbnail> createState() => _VideoStoryThumbnailState();
}

class _VideoStoryThumbnailState extends State<VideoStoryThumbnail> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
          });
          // Ensure it's at the start
          _controller.seekTo(Duration.zero);
        }
      }).catchError((error) {
         debugPrint("Error loading video thumbnail: $error");
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),
      );
    } else {
      return Container(color: Colors.grey[800]); // Dark placeholder
    }
  }
}
