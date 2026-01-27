import 'package:flutter/material.dart';
import '../../config/api_config.dart';

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic>? user;
  final String profileImage;
  final String? coverImage;
  final VoidCallback onMenuPressed;
  final VoidCallback onAvatarTap;
  final VoidCallback onCoverTap;
  final Color backgroundColor;
  final bool isReadOnly;
  final String heroTag;

  const ProfileHeader({
    super.key,
    this.user,
    required this.profileImage,
    this.coverImage,
    required this.onMenuPressed,
    required this.onAvatarTap,
    required this.onCoverTap,
    required this.backgroundColor,
    this.isReadOnly = false,
    this.heroTag = 'profile_hero',
  });

  bool _isNetworkImage(String path) {
    var p = path.trim().toLowerCase().replaceAll(r'\', '/');
    return p.startsWith('http') || p.startsWith('uploads/');
  }

  String _resolveUrl(String path) {
    // Normalize path separators for checking
    var p = path.trim().replaceAll(r'\', '/');
    if (p.startsWith('http')) return path; // Return original if http

    if (p.startsWith('uploads/')) {
      final base = ApiConfig.baseUrl; // e.g. http://192.168.1.13:5000/api
      final root = base.replaceAll('/api', '');

      // Ensure p doesn't have leading slash if root has trailing, or vice versa
      // actually logic: root + / + p

      if (root.endsWith('/')) {
        return '$root$p';
      }
      return '$root/$p';
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final String resolvedProfileImage = profileImage.isNotEmpty
        ? profileImage
        : (user?['avatar_url'] ?? user?['avatar'] ?? '');

    final String? resolvedCoverImage =
        (coverImage != null && coverImage!.isNotEmpty)
        ? coverImage
        : (user?['cover_image'] ??
              user?['cover_image_url'] ??
              user?['cover_url']);

    ImageProvider? imageProvider(String path) {
      if (path.isEmpty) return null;
      final cleanPath = path.trim();
      if (_isNetworkImage(cleanPath)) {
        return NetworkImage(_resolveUrl(cleanPath));
      }
      return AssetImage(cleanPath) as ImageProvider;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ================= COVER PHOTO =================
        GestureDetector(
          onTap: onCoverTap, // Use the callback
          child: Hero(
            tag: 'cover_hero',
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                gradient:
                    resolvedCoverImage == null || resolvedCoverImage.isEmpty
                    ? LinearGradient(
                        colors: [
                          theme.primaryColor,
                          theme.primaryColor.withValues(alpha: 0.7),
                        ],
                      )
                    : null,
                image:
                    resolvedCoverImage != null && resolvedCoverImage.isNotEmpty
                    ? DecorationImage(
                        image: imageProvider(resolvedCoverImage)!,
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8, top: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isReadOnly)
                          const BackButton(color: Colors.white)
                        else
                          IconButton(
                            icon: Icon(
                              Icons.menu,
                              color: colorScheme.onPrimary,
                            ),
                            onPressed: onMenuPressed,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ================= PROFILE PHOTO =================
        Positioned(
          bottom: -50,
          left: 20,
          child: Stack(
            children: [
              GestureDetector(
                onTap: onAvatarTap, // Always tap to view/edit
                child: Hero(
                  tag: heroTag,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 65,
                      backgroundImage: imageProvider(resolvedProfileImage),
                      backgroundColor: resolvedProfileImage.isEmpty
                          ? Colors.grey[300]
                          : colorScheme.surfaceContainerHighest,
                      child: resolvedProfileImage.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 80, // Larger icon
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
