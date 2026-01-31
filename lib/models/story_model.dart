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
      id: json['id'].toString(),
      name: json['name'] ?? "Unknown",
      avatar: json['avatar'],
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
      storyMetadata: json['story_metadata'] is Map<String, dynamic>
          ? json['story_metadata']
          : null,
      hasViewed: json['has_viewed'] ?? false,
      hasLiked: json['has_liked'] ?? false,
      viewCount: json['view_count'] ?? 0,
      likeCount: json['like_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
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
