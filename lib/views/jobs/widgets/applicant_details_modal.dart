import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/applicant_model.dart';

class ApplicantDetailsModal extends StatelessWidget {
  final Applicant applicant;
  final VoidCallback? onShortlist;
  final VoidCallback? onReject;

  const ApplicantDetailsModal({
    super.key,
    required this.applicant,
    this.onShortlist,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1115), // Dark background as per design
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(context, theme),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Info
                    _buildProfileInfo(theme),
                    const SizedBox(height: 32),
                    
                    // About
                    _buildSectionTitle(theme, "About"),
                    const SizedBox(height: 12),
                    Text(
                      applicant.about.isNotEmpty ? applicant.about : "No detailed bio provided.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Skills
                    _buildSectionTitle(theme, "Skills"),
                    const SizedBox(height: 12),
                    if (applicant.skills.isEmpty)
                      Text("No skills listed.", style: TextStyle(color: Colors.grey))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: applicant.skills.map((skill) => _buildSkillChip(theme, skill)).toList(),
                      ),
                    const SizedBox(height: 32),
                    
                    // Experience
                    _buildSectionTitle(theme, "Experience"),
                    const SizedBox(height: 12),
                    if (applicant.experience.isEmpty)
                      Text("No experience listed.", style: TextStyle(color: Colors.grey))
                    else
                      ...applicant.experience.map((exp) => _buildExperienceItem(theme, exp)),
                    
                    const SizedBox(height: 32),
                    
                    // Education
                    _buildSectionTitle(theme, "Education"),
                    const SizedBox(height: 12),
                    if (applicant.education.isEmpty)
                       Text("No education listed.", style: TextStyle(color: Colors.grey))
                    else
                       ...applicant.education.map((edu) => _buildEducationItem(theme, edu)),
                       
                    const SizedBox(height: 32),
                    
                    // Resume
                    _buildSectionTitle(theme, "Resume"),
                    const SizedBox(height: 12),
                    _buildResumeCard(theme, context),
                  ],
                ),
              ),
            ),
            
            // Footer
            _buildFooter(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Applicant Details",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.grey, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: Colors.blueAccent,
          backgroundImage: (applicant.avatarUrl != null && applicant.avatarUrl!.isNotEmpty)
              ? NetworkImage(applicant.avatarUrl!)
              : null,
          child: (applicant.avatarUrl == null || applicant.avatarUrl!.isEmpty)
              ? Text(
                  applicant.name.isNotEmpty ? applicant.name[0].toUpperCase() : "?",
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                applicant.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                applicant.headline.isNotEmpty ? applicant.headline : "No headline",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    applicant.location.isNotEmpty ? applicant.location : "Unknown",
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSkillChip(ThemeData theme, String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Text(
        skill,
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
      ),
    );
  }
  
  Widget _buildExperienceItem(ThemeData theme, Experience exp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.work_outline, size: 16, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exp.role,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  "${exp.company} • ${exp.duration}",
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationItem(ThemeData theme, Education edu) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.school_outlined, size: 16, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edu.school,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  "${edu.degree} • ${edu.year}",
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeCard(ThemeData theme, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.description_outlined, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  applicant.resumeName.isNotEmpty ? applicant.resumeName : "Resume.pdf",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "PDF Document",
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () async {
                 if (applicant.resumeUrl != null && applicant.resumeUrl!.isNotEmpty) {
                    final Uri url = Uri.parse(applicant.resumeUrl!);
                    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                        if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch ${applicant.resumeUrl}')));
                        }
                    }
                 } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No resume URL available')));
                 }
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text("Download"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: theme.dividerColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: onReject,
              icon: const Icon(Icons.close, size: 18),
              label: const Text("Reject"),
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
                backgroundColor: Colors.redAccent.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onShortlist,
              icon: const Icon(Icons.check, size: 18),
              label: const Text("Shortlist"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B7FFF), // Blue/Purple accent
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
