import 'package:flutter/material.dart';
import 'edit_profile_screen.dart';
import '../bottom_navigation.dart';
import 'settings_screen/settings_screen.dart';
import 'analytics/analytics_dashboard_screen.dart';
import '../../services/secure_storage.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
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
  // List<String> skills = [];

  //changes by juless

  List<Skill> skills = [];
  bool isOverviewSelected = true;

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

      // ✅ MOVING PARSING OUTSIDE SETSTATE (FIX FOR MAIN THREAD OVERLOAD)
      final List<Experience> fetchedExperiences = (data['experiences'] as List? ?? [])
          .map((e) => Experience.fromJson(e))
          .toList();

      final List<Education> fetchedEducations = (data['educations'] as List? ?? [])
          .map((e) => Education.fromJson(e))
          .toList();

      // final List<String> fetchedSkills = (data['skills'] as List? ?? [])
      //     .map((s) => s is Map ? s['name'].toString() : s.toString())
      //     .toList();

      //changes by juless
      final List<Skill> fetchedSkills = (data['skills'] as List? ?? [])
          .map((s) => Skill.fromJson(s))
          .toList();
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      endDrawer: _buildMenuDrawer(theme),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 4),
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
                  onMenuPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                  onCameraPressed: () {},
                  onCoverCameraPressed: () {},
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
              ),
              _divider(theme),
              const RepaintBoundary(child: ProfileStats()),
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
              MaterialPageRoute(builder: (_) => const AnalyticsDashboardScreen()),
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
