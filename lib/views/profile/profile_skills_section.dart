import 'package:flutter/material.dart';

import 'profile_models.dart';

class ProfileSkillsSection extends StatelessWidget {
  // final List<String> skills;

  final List<Skill> skills;
  final VoidCallback onAddSkill;
  final bool isReadOnly;

  const ProfileSkillsSection({
    super.key,
    required this.skills,
    required this.onAddSkill,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Skills",
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (!isReadOnly)
                TextButton(
                  onPressed: onAddSkill,
                  child: Text("Add", style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: skills.map((skill) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Text(
                // skill,
                skill.name,
                style: theme.textTheme.bodyMedium,
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}