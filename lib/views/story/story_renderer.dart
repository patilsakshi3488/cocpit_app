import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cocpit_app/models/story_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:video_player/video_player.dart';
import 'package:cocpit_app/utils/safe_network_image.dart';
import 'package:cocpit_app/views/feed/post_detail_screen.dart';

class StoryRenderer extends StatefulWidget {
  final Story story;
  final VideoPlayerController? videoController;
  final File? previewFile; // NEW: For local preview before upload
  final bool isPreview; // ✅ NEW: Skip strict assertions during preview

  const StoryRenderer({
    super.key,
    required this.story,
    this.videoController,
    this.previewFile,
    this.isPreview = false, // ✅ Default to false
  });

  @override
  State<StoryRenderer> createState() => _StoryRendererState();
}

class _StoryRendererState extends State<StoryRenderer> {
  @override
  Widget build(BuildContext context) {
    final bool isSharedPost =
        widget.story.sharedPost != null ||
        widget.story.storyMetadata?['shared_post_id'] != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 1️⃣ SHARED POST (Highest Priority)
        if (isSharedPost) {
          return _buildSharedPost(constraints);
        }

        // 2️⃣ REGULAR STORY (Website Unified Stack logic)
        return _buildUnifiedStory(constraints);
      },
    );
  }

  Widget _buildUnifiedStory(BoxConstraints constraints) {
    final layers = widget.story.layers;
    final meta = widget.story.storyMetadata ?? {};
    final String? background = meta['background'];
    final bool hasVideoLayer = layers.any(
      (l) => l.type == 'video' && (l.id == 'main-video' || l.id == 'layer'),
    );
    final bool hasImageLayer = layers.any(
      (l) => l.type == 'image' && (l.id == 'main-image' || l.id == 'layer'),
    );

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background (Color/Gradient or Blurred Underlay)
          if (background != null)
            _buildBackground(background)
          else if (widget.story.mediaUrl.isNotEmpty && !widget.isPreview)
            Opacity(
              opacity: 0.5,
              child: Container(
                decoration: const BoxDecoration(color: Colors.black),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.black26,
                    BlendMode.darken,
                  ),
                  child: CachedNetworkImage(
                    imageUrl: widget.story.mediaUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

          // 2. Base Media (Exclusionary Rule)
          // Only show base media if no layer of the same type exists
          if (widget.story.mediaType == 'video' && !hasVideoLayer)
            _buildBaseVideo()
          else if (widget.story.mediaType == 'image' && !hasImageLayer)
            _buildBaseImage(),

          // 3. Live Layers (Text, Stickers, Images, Videos)
          ...layers.map((layer) => _buildLayer(layer, constraints)),
        ],
      ),
    );
  }

  Widget _buildBaseVideo() {
    // Handle processing/failed states
    final status = widget.story.storyMetadata?['media_status'];
    if (status == 'processing') {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 12),
            Text(
              "Processing Video...",
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (widget.videoController != null &&
        widget.videoController!.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: widget.videoController!.value.aspectRatio,
          child: VideoPlayer(widget.videoController!),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }

  Widget _buildBaseImage() {
    if (widget.previewFile != null) {
      return Image.file(widget.previewFile!, fit: BoxFit.contain);
    }
    if (widget.story.mediaUrl.isEmpty) return const SizedBox.shrink();

    return CachedNetworkImage(
      imageUrl: widget.story.mediaUrl,
      fit: BoxFit.contain,
      errorWidget: (_, __, ___) => const Icon(Icons.error, color: Colors.white),
    );
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

  Widget _buildSharedPost(BoxConstraints constraints) {
    if (widget.story.sharedPost != null) {
      final shared = widget.story.sharedPost!;
      return Container(
        color: Colors.black,
        child: Center(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostDetailScreen(post: {"id": shared.postId}),
                ),
              );
            },
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 12),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: safeNetworkImage(shared.author.avatar),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          shared.author.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (shared.media.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: shared.media.first is Map
                            ? shared.media.first['url']
                            : shared.media.first,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 10),
                  const Text(
                    "Tap to view full post",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    // Fallback if sharedPost model didn't parse but metadata has ID
    return _buildDefaultStory(constraints);
  }

  Widget _buildDefaultStory(BoxConstraints constraints) {
    // 🟢 1. PREVIEW FILE TAKES PRIORITY (Local state)
    if (widget.previewFile != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Image.file(
            widget.previewFile!,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.error, color: Colors.white),
          ),
        ),
      );
    }

    // 🟢 2. FALLBACK TO NETWORK (Published state)
    if (widget.story.mediaUrl.isNotEmpty) {
      return Container(
        color: Colors.black,
        child: Center(
          child: widget.story.mediaType == 'video'
              ? _buildSimpleMedia() // Video player logic remains in _buildSimpleMedia
              : CachedNetworkImage(
                  imageUrl: widget.story.mediaUrl,
                  fit: BoxFit.contain,
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error, color: Colors.white),
                ),
        ),
      );
    }

    // 🟡 3. LAST RESORT (Safety net for Preview mode)
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          "Preparing story preview...",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
    );
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
          ..scale(layer.scale, layer.scale, 1.0),
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
