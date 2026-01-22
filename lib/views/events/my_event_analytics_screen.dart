import 'package:flutter/material.dart';
import '../../models/event_model.dart';

class MyEventAnalyticsScreen extends StatelessWidget {
  final EventModel event;

  const MyEventAnalyticsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Event Analytics', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: theme.iconTheme,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _tile(theme, 'Total Registrations', event.totalRegistrations),
            _tile(theme, 'Max Attendees', event.maxAttendees ?? 'Unlimited'),
            // Removed Attended/Status as backend doesn't support them yet
            // _tile(theme, 'Attended', event.attendedCount),
            // _tile(theme, 'Status', event.status),
          ],
        ),
      ),
    );
  }

  Widget _tile(ThemeData theme, String label, Object value) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: theme.dividerColor),
    ),
    child: ListTile(
      title: Text(label, style: theme.textTheme.titleMedium),
      trailing: Text(
        value.toString(), 
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
