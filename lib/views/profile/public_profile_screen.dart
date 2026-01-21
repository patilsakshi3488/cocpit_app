import 'package:flutter/material.dart';
import '../../models/public_user.dart';
import '../../services/public_user_service.dart';
import '../feed/chat_screen.dart';
import 'profile_header.dart';
import 'profile_info_identity.dart';
import 'profile_stats.dart';
import 'profile_about_section.dart';
import 'profile_experience_section.dart';
import 'profile_education_section.dart';
import 'profile_skills_section.dart';
import 'profile_models.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  // final int connectionCount;


  const PublicProfileScreen({super.key,
    required this.userId
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  PublicUser? user;
  bool isLoading = true;
  int connectionCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await PublicUserService.getUserProfile(widget.userId);
      setState(() {
        user = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Public profile load error: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("User profile not found")),
      );
    }

    // Map PublicExperience to Experience model for UI reuse
    final List<Experience> mappedExperiences = user!.experiences.map((e) => Experience(
      title: e.title,
      company: e.company,
      startDate: "Present", // Placeholder as PublicExperience lacks dates
      currentlyWorking: e.isCurrent,
      location: "",
      description: e.description ?? "",
    )).toList();

    // Map PublicEducation to Education model for UI reuse
    final List<Education> mappedEducations = user!.educations.map((e) => Education(
      school: e.school,
      degree: e.degree ?? "",
      fieldOfStudy: "",
      startYear: "",
      currentlyStudying: false,
      description: e.description ?? "",
    )).toList();

    // Map List<String> skills to List<Skill>
    final List<Skill> mappedSkills = user!.skills.map((s) => Skill(
      id: s, // Using name as ID for read-only display
      name: s,
    )).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileHeader(
              user: {
                'avatar_url': user!.avatarUrl,
              },
              profileImage: 'lib/images/profile.jpg',
              onMenuPressed: () {},
              onCameraPressed: () {},
              onCoverCameraPressed: () {},
              backgroundColor: theme.scaffoldBackgroundColor,
              isReadOnly: true,
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
              isReadOnly: true,
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
              onFollow: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Follow functionality coming soon")),
                );
              },
            ),
            _buildDivider(theme),
            ProfileStats(connectionCount: connectionCount),
            _buildDivider(theme),
            ProfileAboutSection(about: user!.about ?? "No about information provided."),
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
