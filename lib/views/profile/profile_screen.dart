import 'package:flutter/material.dart';
import 'edit_profile_screen.dart';
import '../bottom_navigation.dart';
import 'settings_screen/settings_screen.dart';
import 'analytics/analytics_dashboard_screen.dart';
import '../../services/secure_storage.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/feed_service.dart';
import '../login/signin_screen.dart';

import 'profile_models.dart';
import 'profile_header.dart';
import 'profile_info_identity.dart';
import 'profile_stats.dart';
import 'profile_living_resume.dart';
import 'profile_about_section.dart';
import 'profile_experience_section.dart';
import 'profile_education_section.dart';
import 'profile_skills_section.dart';
import 'profile_posts_section.dart';
import 'profile_suggested_section.dart';
import 'profile_modals.dart';
import 'photo_action_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final AuthService authService = AuthService();
  final ProfileService profileService = ProfileService();

  Map<String, dynamic>? profile;
  bool isLoading = true;

  String name = "";
  String headline = "";
  String location = "";
  String about = "";

  String openTo = "Full-time";
  String availability = "Immediate";
  String preference = "Hybrid";

  String profileImage = 'lib/images/profile.jpg';
  String? coverImage;

  List<Experience> experiences = [];
  List<Education> educations = [];
  List<Skill> skills = [];
  List<Map<String, dynamic>> myPosts = []; // Added for posts

  bool isOverviewSelected = true;
  int connectionCount = 0;
  String? latestEducation;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// =========================
  /// LOAD PROFILE + IDENTITY
  /// =========================
  Future<void> _loadProfile() async {
    try {
      final data = await profileService.getMyProfile();
      final identity = await profileService.getIdentity();

      if (!mounted || data == null) return;

      final user = data['user'] ?? {};

      // Fetch connection count if user ID is available
      int count = 0;
      if (user['user_id'] != null) {
        count = await profileService.getConnectionCount(
          user['user_id'].toString(),
        );
      } else if (user['id'] != null) {
        count = await profileService.getConnectionCount(user['id'].toString());
      }

      // ✅ MOVING PARSING OUTSIDE SETSTATE (FIX FOR MAIN THREAD OVERLOAD)
      final List<Experience> fetchedExperiences =
          (data['experiences'] as List? ?? [])
              .map((e) => Experience.fromJson(e))
              .toList();

      final List<Education> fetchedEducations =
          (data['educations'] as List? ?? [])
              .map((e) => Education.fromJson(e))
              .toList();

      final List<Skill> fetchedSkills = (data['skills'] as List? ?? [])
          .map((s) => Skill.fromJson(s))
          .toList();

      // Fetch user's posts
      List<Map<String, dynamic>> fetchedPosts = [];
      try {
        final postsData = await FeedApi.fetchMyPosts();
        // Assuming posts are in a standard paginated format or list
        if (postsData['posts'] != null) {
          fetchedPosts = List<Map<String, dynamic>>.from(postsData['posts']);
        } else if (postsData['data'] != null) {
          fetchedPosts = List<Map<String, dynamic>>.from(postsData['data']);
        }
      } catch (e) {
        debugPrint("⚠️ Failed to load my posts: $e");
      }

      // Determine latest education
      String? educationStr;
      if (user['latestEducation'] != null && user['latestEducation'] is Map) {
        // If backend provides it directly
        final edu = user['latestEducation'];
        educationStr =
            "${edu['school_name'] ?? ''} ${edu['degree'] != null ? '• ${edu['degree']}' : ''}";
      } else if (fetchedEducations.isNotEmpty) {
        // Fallback to first in list (assuming ordered)
        final edu = fetchedEducations.first;
        educationStr =
            "${edu.school} ${edu.degree.isNotEmpty ? '• ${edu.degree}' : ''}";
      }

      setState(() {
        profile = data;

        // ✅ BACKEND-CORRECT KEYS
        name = user['name'] ?? '';
        headline = user['headline'] ?? '';
        location = user['location'] ?? '';
        about = user['about'] ?? '';
        profileImage = user['avatar'] ?? profileImage;

        experiences = fetchedExperiences;
        educations = fetchedEducations;
        skills = fetchedSkills;
        myPosts = fetchedPosts; // Assign posts

        connectionCount = count;
        latestEducation = educationStr;

        if (identity != null) {
          openTo = identity['open_to'] ?? openTo;
          availability = identity['availability'] ?? availability;
          preference = identity['work_preference'] ?? preference;
        }

        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Profile load error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleAvatarUpdate() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    if (!mounted) return;

    // Show loading indicator or toast?
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Uploading avatar...")));

    final success = await profileService.uploadAvatar(File(image.path));

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Avatar updated successfully")),
        );
        await _loadProfile();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update avatar")),
        );
      }
    }
  }

  Future<void> _handleCoverUpdate() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Uploading cover photo...")));

    final success = await profileService.uploadCover(File(image.path));
    debugPrint("✅ uploadCover returned: $success");
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cover photo updated successfully")),
        );
        await _loadProfile();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update cover photo")),
        );
      }
    }
  }

  /// =========================
  /// MODALS
  /// =========================
  void _showExperienceModal({Experience? experience, int? index}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExperienceModal(experience: experience),
    );

    if (result == true) await _loadProfile();
  }

  void _showEducationModal({Education? education, int? index}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EducationModal(education: education),
    );

    if (result == true) await _loadProfile();
  }

  void _showSkillsModal() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SkillsModal(initialSkills: skills),
    );

    if (result == true) await _loadProfile();
  }

  /// =========================
  /// EDIT PROFILE
  /// =========================
  void _navigateToEditProfile() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          initialData: {
            'name': name,
            'headline': headline,
            'jobTitle': profile?['user']?['job_title'] ?? '',
            'company': profile?['user']?['company_name'] ?? '',
            'school': profile?['user']?['school'] ?? '',
            'degree': profile?['user']?['degree'] ?? '',
            'location': location,
            'about': about,
          },
        ),
      ),
    );

    // ✅ FIX 1: Delay the update until navigation is finished
    if (!mounted || result == null) return;

    // 🔥 Let pop animation complete to avoid frame skip
    await Future.delayed(const Duration(milliseconds: 200));

    final success = await profileService.updateProfile(
      fullName: result['name']!,
      headline: result['headline']!,
      jobTitle: result['jobTitle']!,
      company: result['company']!,
      school: result['school']!,
      degree: result['degree']!,
      location: result['location']!,
      about: result['about']!,
    );

    if (success && mounted) {
      await _loadProfile();
    }
  }

  /// =========================
  /// EDIT IDENTITY
  /// =========================
  void _showEditIdentityModal() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditIdentityModal(
        initialOpenTo: openTo,
        initialAvailability: availability,
        initialPreference: preference,
      ),
    );

    if (result == null) return;

    final success = await profileService.updateIdentity(
      openTo: result['openTo']!,
      availability: result['availability']!,
      preference: result['preference']!,
    );

    if (success) {
      setState(() {
        openTo = result['openTo']!;
        availability = result['availability']!;
        preference = result['preference']!;
      });
    }
  }

  /// =========================
  /// POST MANAGEMENT
  /// =========================
  Future<void> _handleDeletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text("Are you sure you want to delete this post?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FeedApi.deletePost(postId);
        setState(() {
          myPosts.removeWhere((p) => p['id'].toString() == postId);
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Post deleted")));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Failed to delete: $e")));
        }
      }
    }
  }

  Future<void> _handleTogglePrivacy(String postId, bool makePrivate) async {
    try {
      await FeedApi.setPostVisibility(postId, makePrivate);
      await _loadProfile(); // Reload to refresh state
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              makePrivate ? "Post is now private" : "Post is now public",
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error updating privacy: $e");
    }
  }

  Future<void> _handleEditPost(String postId) async {
    // Navigate to CreatePostScreen in edit mode (not implemented yet)
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Edit feature coming soon")));
  }

  /// =========================
  /// LOGOUT
  /// =========================
  Future<void> _logout() async {
    try {
      await authService.logout();
    } catch (_) {
      await AppSecureStorage.clearAll();
    }

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      endDrawer: _buildMenuDrawer(theme),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 1),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ RepaintBoundary for heavy components
              RepaintBoundary(
                child: ProfileHeader(
                  user: profile!['user'],
                  profileImage: profileImage,
                  coverImage: coverImage,
                  onMenuPressed: () =>
                      _scaffoldKey.currentState?.openEndDrawer(),
                  onCameraPressed: () {
                    PhotoActionHelper.showPhotoActions(
                      context: context,
                      title: "Profile Photo",
                      imagePath: profileImage,
                      heroTag: 'profile_hero',
                      onUpdate: _handleAvatarUpdate,
                      onDelete: () {}, // Implement delete if API supports it
                    );
                  },
                  onCoverCameraPressed: () {
                    PhotoActionHelper.showPhotoActions(
                      context: context,
                      title: "Cover Photo",
                      imagePath: coverImage,
                      heroTag: 'cover_hero',
                      onUpdate: _handleCoverUpdate,
                      onDelete: () {}, // Implement delete if API supports it
                    );
                  },
                  backgroundColor: theme.scaffoldBackgroundColor,
                ),
              ),
              const SizedBox(height: 80),
              ProfileInfoIdentity(
                name: name,
                headline: headline,
                location: location,
                openTo: openTo,
                availability: availability,
                preference: preference,
                onEditProfile: _navigateToEditProfile,
                onEditIdentity: _showEditIdentityModal,
                connectionCount: connectionCount,
                latestEducation: latestEducation,
              ),
              _divider(theme),

              RepaintBoundary(
                child: ProfileStats(connectionCount: connectionCount),
              ),

              _divider(theme),
              ProfileLivingResume(
                isOverviewSelected: isOverviewSelected,
                onTabChanged: (v) => setState(() => isOverviewSelected = v),
                onUploadResume: () {},
                onDownloadPDF: () {},
              ),
              _divider(theme),
              ProfileAboutSection(about: about),
              _divider(theme),
              ProfileExperienceSection(
                experiences: experiences,
                onAddEditExperience: _showExperienceModal,
              ),

              ProfileEducationSection(
                educations: educations,
                onAddEditEducation: _showEducationModal,
              ),

              _divider(theme),
              ProfileSkillsSection(
                skills: skills,
                onAddSkill: _showSkillsModal,
              ),
              _divider(theme),
              // LATEST POSTS SECTION
              ProfileLatestPostsSection(
                posts: myPosts,
                userName: name,
                onSeeAllPosts: () {
                  // Navigate to all posts (optional)
                },
                onDeletePost: _handleDeletePost,
                onEditPost: _handleEditPost,
                onTogglePrivacy: _handleTogglePrivacy,
              ),
              _divider(theme),
              ProfileSuggestedSection(suggestedUsers: const []),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Divider(color: theme.dividerColor, thickness: 1, height: 80),
    );
  }

  Widget _buildMenuDrawer(ThemeData theme) {
    return Drawer(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text("Analytics"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AnalyticsDashboardScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
