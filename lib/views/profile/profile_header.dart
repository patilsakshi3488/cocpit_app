import 'package:flutter/material.dart';
import '../fullscreen_image.dart';

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic>? user;
  final String profileImage;
  final String? coverImage;
  final VoidCallback onMenuPressed;
  final VoidCallback onCameraPressed;
  final VoidCallback onCoverCameraPressed;
  final Color backgroundColor;
  final bool isReadOnly;

  const ProfileHeader({
    super.key,
    this.user,
    required this.profileImage,
    this.coverImage,
    required this.onMenuPressed,
    required this.onCameraPressed,
    required this.onCoverCameraPressed,
    required this.backgroundColor,
    this.isReadOnly = false,
  });

  bool _isNetworkImage(String path) {
    return path.trim().toLowerCase().startsWith('http');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final String resolvedProfileImage =
        user?['avatar_url']?.toString().isNotEmpty == true
        ? user!['avatar_url']
        : profileImage;

    final String? resolvedCoverImage =
        user?['cover_url']?.toString().isNotEmpty == true
        ? user!['cover_url']
        : coverImage;

    ImageProvider? imageProvider(String path) {
      if (path.isEmpty) return null;
      final cleanPath = path.trim();
      return _isNetworkImage(cleanPath)
          ? NetworkImage(cleanPath)
          : AssetImage(cleanPath) as ImageProvider;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ================= COVER PHOTO =================
        GestureDetector(
          onTap: () {
            if (resolvedCoverImage != null && resolvedCoverImage.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImage(
                    imagePath: resolvedCoverImage,
                    tag: 'cover_hero',
                  ),
                ),
              );
            }
          },
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
                        if (!isReadOnly) ...[
                          IconButton(
                            icon: Icon(
                              Icons.camera_alt_outlined,
                              color: colorScheme.onPrimary,
                            ),
                            onPressed: onCoverCameraPressed,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.menu,
                              color: colorScheme.onPrimary,
                            ),
                            onPressed: onMenuPressed,
                          ),
                        ] else
                          const BackButton(color: Colors.white),
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
                onTap: () {
                  if (!isReadOnly) {
                    onCameraPressed();
                  } else if (resolvedProfileImage.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenImage(
                          imagePath: resolvedProfileImage,
                          tag: 'profile_hero',
                        ),
                      ),
                    );
                  }
                },
                child: Hero(
                  tag: 'profile_hero',
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
