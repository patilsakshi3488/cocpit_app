import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import 'event_register_sheet.dart';
import 'my_event_analytics_screen.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventModel event;
  final bool isRegistered;
  final bool isSaved;
  final Function(bool) onSaveToggle;
  final VoidCallback onRegister;
  final VoidCallback onCancelRegistration;

  const EventDetailsScreen({
    super.key,
    required this.event,
    this.isRegistered = false,
    this.isSaved = false,
    required this.onSaveToggle,
    required this.onRegister,
    required this.onCancelRegistration,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late EventModel _event;
  late bool _isSaved;
  late bool _isRegistered;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _isSaved = widget.isSaved;
    _isRegistered = widget.isRegistered;
    _initData();
  }

  Future<void> _initData() async {
    // Parallel fetch: details (for attendee count) and registration status
    try {
      final results = await Future.wait([
         EventService.getEventById(widget.event.id),
         EventService.checkRegistrationStatus(widget.event.id)
      ]);

      final details = results[0] as EventModel;
      final isReg = results[1] as bool;

      if (mounted) {
        setState(() {
          _event = details.copyWith(
            // Preserve local helper properties if needed, but getEventById should return fresh data.
            // But getEventById response might NOT have isRegistered/isSaved populated if we don't handle it in service properly,
            // (Service calls endpoint which returns e.*, but my SQL analysis says e.*, organizer_name, registered_count).
            // So we need to merge states.
            isRegistered: isReg,
            isSaved: widget.isSaved, // Keep passed state or assume false if not fetched
            createdByMe: widget.event.createdByMe,
          );
          _isRegistered = isReg;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading event details: $e");
      if (mounted) {
         // Fallback to widget.event if fetch fails, but still mark loading done
         setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleSave() async {
    // Optimistic update
    setState(() {
      _isSaved = !_isSaved;
    });

    try {
      if (_isSaved) {
        await EventService.saveEvent(_event.id);
      } else {
        await EventService.unsaveEvent(_event.id);
      }
      widget.onSaveToggle(_isSaved);
    } catch (e) {
      // Revert if error
      if (mounted) {
        setState(() {
          _isSaved = !_isSaved;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update save status")));
      }
    }
  }

  Future<void> _unregister() async {
     try {
       final success = await EventService.unregisterFromEvent(_event.id);
       if (success) {
         setState(() {
           _isRegistered = false;
           _event.totalRegistrations = (_event.totalRegistrations - 1).clamp(0, 999999);
         });
         widget.onCancelRegistration();
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Unregistered successfully")));
       }
     } catch(e) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to unregister")));
     }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ImageProvider imgProv;
    if (_event.image.startsWith('http')) {
       imgProv = NetworkImage(_event.image);
    } else {
       imgProv = AssetImage(_event.image);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                backgroundColor: theme.scaffoldBackgroundColor,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.6), // Fixed compatibility
                    child: const BackButton(color: Colors.white),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: _toggleSave,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: _isSaved ? theme.primaryColor.withOpacity(0.2) : Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _isSaved ? theme.primaryColor : Colors.white24),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isSaved ? Icons.bookmark : Icons.bookmark_border,
                              size: 18,
                              color: _isSaved ? theme.primaryColor : Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isSaved ? 'Saved' : 'Save Event',
                              style: TextStyle(
                                color: _isSaved ? theme.primaryColor : Colors.white,
                                fontWeight: _isSaved ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image(image: imgProv, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey)),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 24,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _event.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_isRegistered)
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Registered',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About this event',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _event.description,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                      ),
                      const SizedBox(height: 32),
                      _infoRow(theme, Icons.calendar_today, 'Date and Time', '${_event.startDate} · ${_event.startTime}'),
                      _infoRow(theme, Icons.location_on_outlined, 'Location', _event.location ?? 'Online'),
                      _infoRow(theme, Icons.people_outline, 'Attendees', '${_event.totalRegistrations} going'),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Organizers',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 20),
                            _organizerItem(theme, Icons.person_outline, _event.organizerName ?? 'Organizer'),
                            // _organizerItem(theme, Icons.email_outlined, 'contact@thecompany.com'),
                            // _organizerItem(theme, Icons.phone_outlined, '+1 234 567 890'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 140),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: _actionButtons(context, theme),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons(BuildContext context, ThemeData theme) {
    if (_isLoading) {
      return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()));
    }

    if (_event.createdByMe) {
      return SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MyEventAnalyticsScreen(event: _event)),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text(
            'View Analytics',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    if (_isRegistered) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mock Ticket Download')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'Download Ticket',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: OutlinedButton(
              onPressed: _unregister,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.dividerColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'Cancel Registration',
                style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () async {
          final res = await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => EventRegisterSheet(event: _event),
          );
          if (res == true) {
            setState(() {
               _isRegistered = true;
               _event.totalRegistrations++;
            });
            widget.onRegister();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text(
          'Register for this event',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _infoRow(ThemeData theme, IconData icon, String title, String sub) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _organizerItem(ThemeData theme, IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Icon(icon, color: theme.textTheme.bodySmall?.color, size: 20),
            const SizedBox(width: 12),
            Text(text, style: theme.textTheme.bodyLarge),
          ],
        ),
      );
}
