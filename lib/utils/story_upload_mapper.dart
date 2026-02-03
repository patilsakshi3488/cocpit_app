class StoryUploadMapper {
  /// Builds a payload for StoryService.createStory that ensures web compatibility.
  ///
  /// [cloudinaryUrl] MUST be present. For shared posts, use the post image as truth.
  /// [mediaType] 'image' or 'video'
  static Map<String, dynamic> buildPayload({
    required String cloudinaryUrl,
    required String mediaType,
    String? title,
    String? description,
    Map<String, dynamic>? editorMetadata,
    String? publicId,
    String? sharedPostId,
  }) {
    // ✅ Rule #1 (non-negotiable): NO story should ever be created without a valid media_url.
    assert(cloudinaryUrl.isNotEmpty, 'media_url must never be empty');

    return {
      "media_url": cloudinaryUrl,
      "media_type": mediaType,
      "public_id": publicId,
      "title": title ?? "",
      "description": description ?? "",
      "shared_post_id": sharedPostId,
      "story_metadata": {
        if (editorMetadata != null)
          ..._sanitizeMetadata(editorMetadata, cloudinaryUrl),
        if (editorMetadata?['layers'] != null &&
            (editorMetadata!['layers'] as List).isNotEmpty)
          "editor": true,
      },
    };
  }

  static Map<String, dynamic> _sanitizeMetadata(
    Map<String, dynamic> metadata,
    String cloudinaryUrl,
  ) {
    final Map<String, dynamic> sanitized = Map.from(metadata);
    if (sanitized['layers'] != null && sanitized['layers'] is List) {
      final List layers = sanitized['layers'];
      for (var layer in layers) {
        if (layer is Map &&
            (layer['id'] == 'main-image' || layer['id'] == 'main-video')) {
          // ✅ Website Rule: metadata source MUST match media_url for the base layer
          layer['src'] = cloudinaryUrl;
        }
      }
    }
    return sanitized;
  }
}
