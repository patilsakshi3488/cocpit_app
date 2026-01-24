import 'package:flutter/material.dart';

class PrivacySettings extends StatefulWidget {
  const PrivacySettings({super.key});

  @override
  State<PrivacySettings> createState() => _PrivacySettingsState();
}

class _PrivacySettingsState extends State<PrivacySettings> {
  bool profileVisibility = true;
  bool showActivityStatus = true;
  bool searchEngineIndexing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Privacy & Security"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSwitchOption(
                "Profile Visibility", 
                "Make your profile visible to everyone", 
                profileVisibility, 
                (v) => setState(() => profileVisibility = v),
              ),
              const SizedBox(height: 16),
              _buildSwitchOption(
                "Show Activity Status", 
                "Let others see when you're online", 
                showActivityStatus, 
                (v) => setState(() => showActivityStatus = v),
              ),
              const SizedBox(height: 16),
              _buildSwitchOption(
                "Search Engine Indexing", 
                "Allow search engines to show your profile", 
                searchEngineIndexing, 
                (v) => setState(() => searchEngineIndexing = v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchOption(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: colorScheme.onPrimary,
          activeTrackColor: theme.primaryColor,
        ),
      ],
    );
  }
}
