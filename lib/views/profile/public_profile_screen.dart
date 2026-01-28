import 'package:flutter/material.dart';
import '../../models/public_user.dart';
import '../../services/public_user_service.dart';
import '../../services/profile_service.dart';
import '../../services/feed_service.dart';
import '../../services/secure_storage.dart';
import '../../views/profile/profile_posts_section.dart';
import '../../views/feed/chat_screen.dart';
import 'profile_header.dart';
import 'profile_info_identity.dart';
import 'profile_stats.dart';
import 'profile_about_section.dart';
import 'profile_experience_section.dart';
import 'profile_education_section.dart';
import 'profile_skills_section.dart';
import 'profile_models.dart';
import 'profile_photo_viewer.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  PublicUser? user;
  bool isLoading = true;
  int connectionCount = 0;
  bool isFollowing = false;
  final ProfileService _profileService = ProfileService();
  List<Map<String, dynamic>> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Safety check: If this is ME, redirect to main profile
    if (widget.userId != "me") {
      final myId = await AppSecureStorage.getCurrentUserId();
      if (myId == widget.userId && mounted) {
        Navigator.pushReplacementNamed(context, '/profile');
        return;
      }
    }

    try {
      final data = await PublicUserService.getUserProfile(widget.userId);

      debugPrint("load profile"+widget.userId);
      // Fetch Posts
      final postsData = await FeedApi.fetchUserPosts(userId: widget.userId);
      final fetchedPosts = List<Map<String, dynamic>>.from(
        postsData['posts'] ?? [],
      );

      // Fetch Connection Count
      final count = await _profileService.getConnectionCount(widget.userId);

      setState(() {
        user = data;
        isFollowing = data.isFollowing ?? false;
        _posts = fetchedPosts;
        connectionCount = count;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Public profile load error: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _toggleFollow() async {
    final previousState = isFollowing;
    setState(() => isFollowing = !isFollowing);

    bool success;
    if (previousState) {
      // Was following, now unfollow
      success = await _profileService.unfollowUser(widget.userId);
    } else {
      // Was not following, now follow
      success = await _profileService.followUser(widget.userId);
    }

    if (!success && mounted) {
      // Revert
      setState(() => isFollowing = previousState);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Action failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("User profile not found")),
      );
    }

    // Map PublicExperience to Experience model for UI reuse
    final List<Experience> mappedExperiences = user!.experiences
        .map(
          (e) => Experience(
            title: e.title,
            company: e.company,
            startDate: "Present", // Placeholder as PublicExperience lacks dates
            currentlyWorking: e.isCurrent,
            location: "",
            description: e.description ?? "",
          ),
        )
        .toList();

    // Map PublicEducation to Education model for UI reuse
    final List<Education> mappedEducations = user!.educations
        .map(
          (e) => Education(
            school: e.school,
            degree: e.degree ?? "",
            fieldOfStudy: "",
            startYear: "",
            currentlyStudying: false,
            description: e.description ?? "",
          ),
        )
        .toList();

    // Map List<String> skills to List<Skill>
    final List<Skill> mappedSkills = user!.skills
        .map(
          (s) => Skill(
            id: s, // Using name as ID for read-only display
            name: s,
          ),
        )
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileHeader(
              user: {
                'avatar_url': user!.avatarUrl,
                'cover_image_url': user!.coverImageUrl,
              },
              profileImage: user!.avatarUrl ?? '',
              coverImage: user!.coverImageUrl,
              onMenuPressed: () {},
              onAvatarTap: () {
                // Open viewer for public profile (read-only)
                if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilePhotoViewer(
                        imagePath: user!.avatarUrl,
                        heroTag: 'profile_hero_${widget.userId}', // Unique tag
                        isCurrentUser: false,
                        onUpdate: (_) async {}, // No-op
                        onDelete: () async {}, // No-op
                      ),
                    ),
                  );
                }
              },
              onCoverTap: () {
                if (user?.coverImageUrl != null &&
                    user!.coverImageUrl!.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilePhotoViewer(
                        imagePath: user!.coverImageUrl,
                        heroTag: 'cover_hero_${widget.userId}',
                        isCurrentUser: false,
                        isCover: true,
                        onUpdate: (_) async {},
                        onDelete: () async {},
                      ),
                    ),
                  );
                }
              },
              backgroundColor: theme.scaffoldBackgroundColor,
              isReadOnly: true,
              heroTag: 'profile_hero_${widget.userId}',
            ),
            const SizedBox(height: 80),
            ProfileInfoIdentity(
              name: user!.fullName,
              headline: user!.headline ?? "",
              location: user!.location ?? "",
              openTo: "Full-time",
              availability: "Immediate",
              preference: "Hybrid",
              onEditProfile: () {},
              onEditIdentity: () {},
              connectionCount: connectionCount,
              isReadOnly: true,
              isFollowing: isFollowing,
              onMessage: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PersonalChatScreen(
                      name: user!.fullName,
                      role: user!.headline ?? "Connection",
                      color: theme.primaryColor,
                    ),
                  ),
                );
              },
              onFollow: _toggleFollow,
            ),
            _buildDivider(theme),
            ProfileStats(connectionCount: connectionCount),
            _buildDivider(theme),

            _buildDivider(theme),
            ProfileAboutSection(
              about: user!.about ?? "No about information provided.",
            ),
            _buildDivider(theme),
            ProfileExperienceSection(
              experiences: mappedExperiences,
              onAddEditExperience: ({experience, index}) {},
              isReadOnly: true,
            ),
            _buildDivider(theme),
            ProfileEducationSection(
              educations: mappedEducations,
              onAddEditEducation: ({education, index}) {},
              isReadOnly: true,
            ),
            _buildDivider(theme),
            ProfileSkillsSection(
              skills: mappedSkills,
              onAddSkill: () {},
              isReadOnly: true,
            ),
            _buildDivider(theme),

            // 🔥 Posts Section (Moved to bottom)
            if (_posts.isNotEmpty)
              ProfileLatestPostsSection(
                posts: _posts,
                userName: user!.fullName,
                onSeeAllPosts: () {},
                onDeletePost: (_) {}, // Read-only for public profile
                onEditPost: (_) {},
                onTogglePrivacy: (_, __) {},
                userId: widget.userId,
                isOwner: false,
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Divider(color: theme.dividerColor, thickness: 1, height: 80),
    );
  }
}
