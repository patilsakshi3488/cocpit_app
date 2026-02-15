import 'dart:convert';// NEW

class StoryGroup {
  final StoryAuthor author;
  final bool isCurrentUser;
  final String? latestStoryAt;
  final List<Story> stories;

  StoryGroup({
    required this.author,
    required this.isCurrentUser,
    this.latestStoryAt,
    required this.stories,
  });

  factory StoryGroup.fromJson(Map<String, dynamic> json) {
    return StoryGroup(
      author: StoryAuthor.fromJson(json['author']),
      isCurrentUser: json['is_current_user'] ?? false,
      latestStoryAt: json['latest_story_at'],
      stories:
          (json['stories'] as List?)?.map((e) => Story.fromJson(e)).toList() ??
          [],
    );
  }
}

class StoryAuthor {
  final String id;
  final String name;
  final String? avatar;

  StoryAuthor({required this.id, required this.name, this.avatar});

  factory StoryAuthor.fromJson(Map<String, dynamic> json) {
    return StoryAuthor(
      id: (json['id'] ?? json['user_id'] ?? "").toString(),
      name: json['name'] ?? json['full_name'] ?? json['username'] ?? "Unknown",
      avatar: json['avatar'] ?? json['avatar_url'] ?? json['profile_picture'],
    );
  }
}

class Story {
  final String storyId;
  final String? title;
  final String? description;
  final String mediaUrl;
  final String mediaType; // 'image' or 'video'
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isAuthor;
  final Map<String, dynamic>? storyMetadata; // NEW: For linked posts etc.
  bool hasViewed; // mutable for optimistic updates
  bool hasLiked; // mutable for optimistic updates
  int viewCount; // mutable
  int likeCount; // mutable
  int commentCount; // mutable

  List<StoryLayer> get layers {
    if (storyMetadata == null || storyMetadata!['layers'] == null) {
      return [];
    }
    try {
      final list = storyMetadata!['layers'] as List;
      return list.map((e) => StoryLayer.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  final SharedPost? sharedPost;
  // NEW: For parsed shared post data

  Story({
    required this.storyId,
    this.title,
    this.description,
    required this.mediaUrl,
    required this.mediaType,
    required this.createdAt,
    required this.expiresAt,
    required this.isAuthor,
    this.storyMetadata,
    this.sharedPost,
    required this.hasViewed,
    required this.hasLiked,
    required this.viewCount,
    required this.likeCount,
    required this.commentCount,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      storyId: json['story_id'].toString(),
      title: json['title'],
      description: json['description'],
      mediaUrl: json['media_url'] ?? "",
      mediaType: json['media_type'] ?? "image",
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      isAuthor: json['is_author'] ?? false,
      storyMetadata: _parseMetadata(json['story_metadata']),
      sharedPost: json['shared_post'] != null
          ? SharedPost.fromJson(json['shared_post'])
          : null,
      hasViewed: json['has_viewed'] ?? false,
      hasLiked: json['has_liked'] ?? false,
      viewCount: json['view_count'] ?? 0,
      likeCount: json['like_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
    );
  }

  static Map<String, dynamic>? _parseMetadata(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (e) {
        // ignore error
      }
    }
    return null;
  }
}

class SharedPost {
  final String postId;
  final StoryAuthor author;
  final List<dynamic> media;

  SharedPost({required this.postId, required this.author, required this.media});

  factory SharedPost.fromJson(Map<String, dynamic> json) {
    return SharedPost(
      postId: json['post_id']?.toString() ?? "",
      author: StoryAuthor.fromJson(json['author'] ?? {}),
      media: json['media'] ?? [],
    );
  }
}

class StoryLayer {
  final String id;
  final String type; // 'image', 'video', 'text', 'sticker'
  final double x;
  final double y;
  final double width;
  final double height; // Might be 'auto' in JSON, handle carefully
  final double rotation;
  final double scale;
  final int zIndex;
  final String? src;
  final String? content;
  final Map<String, dynamic>? style;

  StoryLayer({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotation,
    required this.scale,
    required this.zIndex,
    this.src,
    this.content,
    this.style,
  });

  factory StoryLayer.fromJson(Map<String, dynamic> json) {
    return StoryLayer(
      id: json['id']?.toString() ?? "",
      type: json['type'] ?? "image",
      x: (json['x'] ?? 50).toDouble(),
      y: (json['y'] ?? 50).toDouble(),
      width: (json['width'] ?? 100).toDouble(),
      height: (json['height'] is num)
          ? (json['height'] as num).toDouble()
          : 0.0,
      rotation: (json['rotation'] ?? 0).toDouble(),
      scale: (json['scale'] ?? 1).toDouble(),
      zIndex: json['zIndex'] ?? 0,
      src: json['src'],
      content: json['content'],
      style: json['style'],
    );
  }
}

class StoryComment {
  final String id;
  final String storyId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final int likeCount;
  final bool isLiked;
  final String? userAvatar; // Optional: helper for UI if included in response
  final String? userName; // Optional: helper for UI if included in response

  StoryComment({
    required this.id,
    required this.storyId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.likeCount,
    required this.isLiked,
    this.userAvatar,
    this.userName,
  });

  factory StoryComment.fromJson(Map<String, dynamic> json) {
    return StoryComment(
      id: json['id']?.toString() ?? json['comment_id']?.toString() ?? "",
      storyId: json['story_id']?.toString() ?? "",
      userId:
          json['user_id']?.toString() ?? json['author_id']?.toString() ?? "",
      content: json['content'] ?? "",
      createdAt: DateTime.tryParse(json['created_at'] ?? "") ?? DateTime.now(),
      likeCount: json['like_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      userAvatar:
          json['user']?['avatar'] ?? json['user_avatar'] ?? json['avatar_url'],
      userName:
          json['user']?['name'] ??
          json['user']?['full_name'] ??
          json['user']?['username'] ??
          json['user_name'] ??
          json['username'] ??
          json['author_name'] ??
          json['full_name'] ??
          json['name'],
    );
  }
}
