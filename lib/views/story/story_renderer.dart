import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cocpit_app/models/story_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:video_player/video_player.dart';
import 'package:cocpit_app/services/feed_service.dart';
import 'package:cocpit_app/utils/safe_network_image.dart';
import 'package:cocpit_app/views/feed/post_detail_screen.dart';
import 'package:cocpit_app/views/profile/public_profile_screen.dart';

class StoryRenderer extends StatefulWidget {
  final Story story;
  final VideoPlayerController? videoController;
  final File? previewFile; // NEW: For local preview before upload

  const StoryRenderer({
    super.key,
    required this.story,
    this.videoController,
    this.previewFile,
  });

  @override
  State<StoryRenderer> createState() => _StoryRendererState();
}

class _StoryRendererState extends State<StoryRenderer> {
  @override
  Widget build(BuildContext context) {
    // ===============================================
    // SHARED POST RENDERING (Instagram Style)
    // ===============================================
    if (widget.story.sharedPost != null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Background
                _buildBackground(
                  widget.story.storyMetadata?['background'] ?? '',
                ),

                // 2. Post Card (Centered & Clickable)
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostDetailScreen(
                            post: {"id": widget.story.sharedPost!.postId},
                          ),
                        ),
                      );
                    },
                    child: _buildSharedPostCard(widget.story.sharedPost!),
                  ),
                ),

                // 3. (REMOVED: Author overlay handled by StoryViewer header instead)
              ],
            ),
          );
        },
      );
    }

    // ===============================================
    // NORMAL STORY RENDERING (Restored)
    // ===============================================
    final bool isImage = widget.story.mediaType == 'image';
    final bool renderLayers =
        widget.story.mediaType == 'video' || widget.story.mediaType == 'poll';

    final sharedPostId = widget.story.storyMetadata?['shared_post_id'];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.story.storyMetadata?['background'] != null &&
                  isImage == false)
                _buildBackground(widget.story.storyMetadata!['background']),

              Positioned.fill(child: _buildSimpleMedia()),

              if (renderLayers)
                ...widget.story.layers.map(
                  (layer) => _buildLayer(layer, constraints),
                ),

              if (sharedPostId != null)
                _buildSharedPostInteraction(sharedPostId),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSharedPostCard(SharedPost post) {
    final imgUrl = (post.media.isNotEmpty)
        ? (post.media.first is Map ? post.media.first['url'] : post.media.first)
        : null;

    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: safeNetworkImage(post.author.avatar),
                radius: 10,
                backgroundColor: Colors.grey[200],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  post.author.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (imgUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imgUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: Colors.grey),
                ),
              ),
            ),
          const Text(
            "Tap to view full post",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedPostInteraction(String postId) {
    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () {
            // Navigate to post (Implementation depends on routing)
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  "View Post",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, color: Colors.black, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _fetchPost(String id) async {
    try {
      return await FeedApi.fetchSinglePost(id);
    } catch (e) {
      return null;
    }
  }

  Widget _buildBackground(String bg) {
    if (bg.startsWith('#')) {
      return Container(color: _parseColor(bg));
    }
    if (bg.contains('gradient')) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          ),
        ),
      );
    }
    return Container(color: Colors.black);
  }

  Widget _buildSimpleMedia() {
    if (widget.story.mediaType == 'video') {
      if (widget.videoController != null &&
          widget.videoController!.value.isInitialized) {
        return Center(
          child: AspectRatio(
            aspectRatio: widget.videoController!.value.aspectRatio,
            child: VideoPlayer(widget.videoController!),
          ),
        );
      }
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (widget.previewFile != null) {
      return Image.file(
        widget.previewFile!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.error, color: Colors.white),
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.story.mediaUrl,
      fit: BoxFit.contain,
      errorWidget: (context, url, error) =>
          const Icon(Icons.error, color: Colors.white),
    );
  }

  Widget _buildLayer(StoryLayer layer, BoxConstraints constraints) {
    // x, y are percentages of center position
    final alignX = (layer.x - 50) / 50;
    final alignY = (layer.y - 50) / 50;

    return Align(
      alignment: Alignment(alignX, alignY),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..rotateZ(layer.rotation * math.pi / 180)
          ..scale(layer.scale),
        child: _buildLayerContent(layer, constraints),
      ),
    );
  }

  Widget _buildLayerContent(StoryLayer layer, BoxConstraints constraints) {
    final w = constraints.maxWidth * (layer.width / 100);
    // Use height if present (>0), otherwise null to let child determine or auto-fit
    final h = (layer.height > 0)
        ? constraints.maxHeight * (layer.height / 100)
        : null;

    if (layer.type == 'text') {
      return Container(
        constraints: BoxConstraints(
          maxWidth: w, // Constrain max width but allow auto-sizing below that
        ),
        padding: const EdgeInsets.all(4),
        child: Text(
          layer.content ?? "",
          textAlign: _getTextAlign(layer.style?['textAlign']),
          style: GoogleFonts.getFont(
            layer.style?['fontFamily'] ?? 'Inter',
            textStyle: TextStyle(
              color: _parseColor(layer.style?['color']),
              fontSize: (layer.style?['fontSize'] ?? 24).toDouble(),
              fontWeight: _getFontWeight(layer.style?['fontWeight']),
              fontStyle: layer.style?['fontStyle'] == 'italic'
                  ? FontStyle.italic
                  : FontStyle.normal,
              shadows: const [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 2,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Handle image/sticker/video sources
    // Fallback logic: if src is missing/empty and it is main-image, use mediaUrl.
    final src =
        (layer.src == null || layer.src!.isEmpty) && layer.id == 'main-image'
        ? widget.story.mediaUrl
        : layer.src ?? "";

    // If we have a preview file and this is the main image
    if (widget.previewFile != null && layer.id == 'main-image') {
      return SizedBox(
        width: w,
        height: h,
        child: Image.file(widget.previewFile!, fit: BoxFit.contain),
      );
    }

    if (src.isEmpty) return const SizedBox.shrink();

    if (layer.type == 'image' || layer.type == 'sticker') {
      return SizedBox(
        width: w,
        height: h,
        child: CachedNetworkImage(imageUrl: src, fit: BoxFit.contain),
      );
    }

    if (layer.type == 'video') {
      // Only main video supported via controller for now
      if (layer.id == 'main-video' || src == widget.story.mediaUrl) {
        if (widget.videoController == null) return const SizedBox.shrink();
        return SizedBox(
          width: w,
          height: h,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: widget.videoController!.value.size.width,
              height: widget.videoController!.value.size.height,
              child: VideoPlayer(widget.videoController!),
            ),
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }

  Color _parseColor(String? hex) {
    if (hex == null) return Colors.white;
    try {
      if (hex.startsWith('#')) {
        // handle #RGB or #RRGGBB
        String cleanHex = hex.substring(1);
        if (cleanHex.length == 3) {
          cleanHex = cleanHex.split('').map((c) => '$c$c').join();
        }
        if (cleanHex.length == 6) {
          return Color(int.parse(cleanHex, radix: 16) + 0xFF000000);
        }
      }
    } catch (_) {}
    return Colors.white;
  }

  TextAlign _getTextAlign(String? align) {
    if (align == 'center') return TextAlign.center;
    if (align == 'right') return TextAlign.right;
    return TextAlign.left;
  }

  FontWeight _getFontWeight(dynamic weight) {
    if (weight == 'bold') return FontWeight.bold;
    if (weight == 'normal') return FontWeight.normal;
    if (weight is int) {
      if (weight >= 700) return FontWeight.bold;
    }
    return FontWeight.normal;
  }
}
