class SearchUser {
  final String id;
  final String fullName;
  final String? headline;
  final String? avatarUrl;
  final String? accountType;

  SearchUser({
    required this.id,
    required this.fullName,
    this.headline,
    this.avatarUrl,
    this.accountType,
  });

  factory SearchUser.fromJson(Map<String, dynamic> json) {
    // Handle nested 'user' if present (API consistency)
    final userData = json['user'] ?? json;

    return SearchUser(
      // Allow flexible ID types and keys
      id: userData['id']?.toString() ?? userData['user_id']?.toString() ?? '',

      // Allow 'name' or 'full_name'
      fullName: userData['full_name'] ?? userData['name'] ?? 'Unknown User',

      headline: userData['headline'],

      // Allow 'avatar' or 'avatar_url'
      avatarUrl: userData['avatar'] ?? userData['avatar_url'],

      accountType: userData['account_type'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "full_name": fullName,
      "headline": headline,
      "avatar_url": avatarUrl,
      "account_type": accountType,
    };
  }
}
