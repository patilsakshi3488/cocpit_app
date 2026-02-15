import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';

class MyEventAnalyticsScreen extends StatefulWidget {
  final EventModel event;

  const MyEventAnalyticsScreen({super.key, required this.event});

  @override
  State<MyEventAnalyticsScreen> createState() => _MyEventAnalyticsScreenState();
}

class _MyEventAnalyticsScreenState extends State<MyEventAnalyticsScreen> {
  List<Map<String, dynamic>> _registrants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRegistrants();
  }

  Future<void> _loadRegistrants() async {
    try {
      final users = await EventService.getEventRegistrants(widget.event.id);
      if (mounted) {
        setState(() {
          _registrants = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tile(theme, 'Total Registrations', widget.event.totalRegistrations),
            _tile(theme, 'Max Attendees', widget.event.maxAttendees ?? 'Unlimited'),
            
            const SizedBox(height: 24),
            Text(
              "Registered Users",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_registrants.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    "No registered users yet",
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                  ),
                ),
              )
            else
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _registrants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final user = _registrants[i];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                          child: Text(
                            (user['name'] ?? 'U')[0].toUpperCase(),
                            style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['name'] ?? 'Unknown',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (user['email'] != null)
                                Text(
                                  user['email'],
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
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

