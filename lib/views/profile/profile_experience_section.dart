import 'package:flutter/material.dart';
import 'profile_models.dart';

class ProfileExperienceSection extends StatelessWidget {
  final List<Experience> experiences;
  final ExperienceCallback onAddEditExperience;
  final bool isReadOnly;

  const ProfileExperienceSection({
    super.key,
    required this.experiences,
    required this.onAddEditExperience,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodySmall = theme.textTheme.bodySmall?.copyWith(
      color: Colors.grey[600],
      fontSize: 13,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Experience",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!isReadOnly)
                TextButton(
                  onPressed: () => onAddEditExperience(),
                  child: Text(
                    "Add",
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...experiences.asMap().entries.map((entry) {
            int idx = entry.key;
            Experience exp = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.business_center,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                exp.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (!isReadOnly)
                              IconButton(
                                icon: Icon(
                                  Icons.edit_outlined,
                                  color: theme.iconTheme.color?.withValues(
                                    alpha: 0.5,
                                  ),
                                  size: 20,
                                ),
                                onPressed: () => onAddEditExperience(
                                  experience: exp,
                                  index: idx,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                        Text(exp.company, style: theme.textTheme.bodyLarge),
                        const SizedBox(height: 2),
                        Text(exp.dateRange, style: bodySmall),
                        if (exp.location.isNotEmpty)
                          Text(exp.location, style: bodySmall),
                        const SizedBox(height: 8),
                        if (exp.description.isNotEmpty)
                          Text(
                            exp.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                              color: theme.textTheme.bodyLarge?.color
                                  ?.withValues(alpha: 0.8),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
