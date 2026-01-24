import 'package:flutter/material.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  bool emailNotifications = true;
  bool pushNotifications = true;
  bool messageNotifications = true;
  bool jobAlerts = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Notifications"),
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
              _buildSwitchOption("Email Notifications", "Receive email updates about your activity", emailNotifications, (v) => setState(() => emailNotifications = v)),
              const SizedBox(height: 16),
              _buildSwitchOption("Push Notifications", "Get notifications on your devices", pushNotifications, (v) => setState(() => pushNotifications = v)),
              const SizedBox(height: 16),
              _buildSwitchOption("Message Notifications", "Get notified about new messages", messageNotifications, (v) => setState(() => messageNotifications = v)),
              const SizedBox(height: 16),
              _buildSwitchOption("Job Alerts", "Receive notifications about job matches", jobAlerts, (v) => setState(() => jobAlerts = v)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchOption(String title, String subtitle, bool value, Function(bool) onChanged) {
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
