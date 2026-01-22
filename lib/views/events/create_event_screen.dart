import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/event_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final virtualLinkCtrl = TextEditingController();
  final maxAttendeesCtrl = TextEditingController();

  String selectedCategory = 'Tech';
  String selectedEventType = 'Online';

  DateTime? startDate;
  TimeOfDay? startTime;
  DateTime? endDate;
  TimeOfDay? endTime;
  DateTime? registrationDeadlineDate;
  TimeOfDay? registrationDeadlineTime;

  bool isFreeEvent = true;
  bool hasWaitlist = true;
  bool isCreating = false;

  File? bannerImage;

  final categories = [
    'Tech',
    'Business',
    'Networking',
    'Workshop',
    'Conference',
    'Summit',
    'Masterclass',
  ];

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    locationCtrl.dispose();
    virtualLinkCtrl.dispose();
    maxAttendeesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text('Create Event', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              pinned: true,
              leading: BackButton(color: colorScheme.onSurface),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bannerPicker(theme),

                      _section(theme, 'Basic Info'),
                      _card(theme, [
                        _field(theme, 'Event Title', titleCtrl),
                        _field(theme, 'Description', descCtrl, maxLines: 3),
                      //
                      //   if (selectedEventType == 'InPerson')
                      //     _field(theme, 'Location', locationCtrl)
                      //   else
                      //     _field(theme, 'Virtual Link', virtualLinkCtrl),
                      ]
                      ),

                      _section(theme, 'Category'),
                      _card(theme, [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: categories
                              .map((c) => _chip(
                            theme,
                            c,
                            selectedCategory == c,
                                () => setState(() => selectedCategory = c),
                          ))
                              .toList(),
                        ),
                      ]),

                      _section(theme, 'Event Type'),
                      _card(theme, [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Row(
                            children: [
                              _chip(
                                theme,
                                'Online',
                                selectedEventType == 'Online',
                                    () => setState(() => selectedEventType = 'Online'),
                              ),
                              const SizedBox(width: 12),
                              _chip(
                                theme,
                                'In-person',
                                selectedEventType == 'InPerson',
                                    () => setState(() => selectedEventType = 'InPerson'),
                              ),
                            ],
                          ),
                        ),


                        if (selectedEventType == 'InPerson')
                            _field(theme, 'Location', locationCtrl)
                          else
                            _field(theme, 'Virtual Link', virtualLinkCtrl),
                      ]),

                      _section(theme, 'Date & Time'),
                      _card(theme, [
                        _dateTimeRow(
                          theme,
                          'Start',
                          startDate,
                          startTime,
                          onDateTap: () async {
                            final d = await _pickDate();
                            if (d != null) setState(() => startDate = d);
                          },
                          onTimeTap: () async {
                            final t = await _pickTime();
                            if (t != null) setState(() => startTime = t);
                          },
                        ),
                        const SizedBox(height: 12),
                        _dateTimeRow(
                          theme,
                          'End',
                          endDate,
                          endTime,
                          onDateTap: () async {
                            final d = await _pickDate();
                            if (d != null) setState(() => endDate = d);
                          },
                          onTimeTap: () async {
                            final t = await _pickTime();
                            if (t != null) setState(() => endTime = t);
                          },
                        ),
                      ]),
                      
                      _section(theme, 'Event Details'),
                      _card(theme, [
                         _field(
                          theme,
                          'Max Attendees',
                          maxAttendeesCtrl,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: hasWaitlist,
                          onChanged: (v) => setState(() => hasWaitlist = v),
                          title: Text('Enable Waitlist', style: theme.textTheme.bodyLarge),
                          activeColor: theme.primaryColor,
                        ),
                         SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: isFreeEvent,
                          onChanged: (v) => setState(() => isFreeEvent = v),
                          title: Text('Free Event', style: theme.textTheme.bodyLarge),
                          activeColor: theme.primaryColor,
                        ),
                      ]),
                      
                      _section(theme, 'Registration'),
                       _card(theme, [
                        Text('Registration Deadline', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        _dateTimeRow(
                          theme,
                          'Deadline',
                          registrationDeadlineDate,
                          registrationDeadlineTime,
                           onDateTap: () async {
                            final d = await _pickDate();
                            if (d != null) setState(() => registrationDeadlineDate = d);
                          },
                          onTimeTap: () async {
                            final t = await _pickTime();
                            if (t != null) setState(() => registrationDeadlineTime = t);
                          },
                        ),
                      ]),


                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: isCreating ? null : _createEvent,
                          child: isCreating
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                            'Create Event',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= BANNER PICKER =================

  Widget _bannerPicker(ThemeData theme) {
    return GestureDetector(
      onTap: _pickBanner,
      child: Container(
        height: 190,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          image: DecorationImage(
            image: bannerImage != null
                ? FileImage(bannerImage!)
                : const AssetImage('lib/images/event_placeholder.jpg')
            as ImageProvider,
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.transparent,
              ],
            ),
          ),
          child: const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Add Event Banner',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickBanner() async {
    final picker = ImagePicker();
    final XFile? file =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);

    if (file != null) {
      setState(() => bannerImage = File(file.path));
    }
  }

  // ================= HELPERS =================

  Widget _section(ThemeData theme, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 16),
    child: Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _card(ThemeData theme, List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: theme.dividerColor),
    ),
    child: Column(children: children),
  );

  Widget _field(ThemeData theme, String label, TextEditingController controller,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: (v) {
          final val = v ?? '';
          if (label == 'Event Title' && val.isEmpty) return 'Event title is required';
          if (label == 'Description' && val.isEmpty) return 'Description is required';
          if (label == 'Virtual Link' && selectedEventType == 'Online' && val.isEmpty) return 'Required for Online events';
          if (label == 'Location' && selectedEventType == 'InPerson' && val.isEmpty) return 'Required for In-person events';
          return null;
        },
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          filled: true,
          fillColor: theme.scaffoldBackgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
        ),
      ),
    );
  }

  Widget _chip(ThemeData theme, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? theme.primaryColor : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(30),
          border: selected ? null : Border.all(color: theme.dividerColor),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : theme.textTheme.bodyMedium?.color)),
      ),
    );
  }

  Widget _dateTimeRow(
      ThemeData theme,
      String label,
      DateTime? date,
      TimeOfDay? time, {
        required VoidCallback onDateTap,
        required VoidCallback onTimeTap,
      }) {
    return Row(
      children: [
        Expanded(
          child: _dateTimeBox(
            theme,
            date == null
                ? '$label Date'
                : '${date.day}/${date.month}/${date.year}',
            Icons.calendar_today,
            onDateTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _dateTimeBox(
            theme,
            time == null ? 'Time' : time.format(context),
            Icons.access_time,
            onTimeTap,
          ),
        ),
      ],
    );
  }

  Widget _dateTimeBox(
      ThemeData theme,
      String value, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.6), size: 18),
            const SizedBox(width: 10),
            Text(value, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _pickDate() {
    return showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      initialDate: DateTime.now(),
    );
  }

  Future<TimeOfDay?> _pickTime() {
    return showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
  }

  // ================= CREATE EVENT =================

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (startDate == null ||
        startTime == null ||
        endDate == null ||
        endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date & time')),
      );
      return;
    }
    if (registrationDeadlineDate == null || registrationDeadlineTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a registration deadline')),
      );
      return;
    }


    setState(() => isCreating = true);

    final start = DateTime(
      startDate!.year, startDate!.month, startDate!.day,
      startTime!.hour, startTime!.minute,
    );
    final end = DateTime(
      endDate!.year, endDate!.month, endDate!.day,
      endTime!.hour, endTime!.minute,
    );
    final deadline = DateTime(
      registrationDeadlineDate!.year, registrationDeadlineDate!.month, registrationDeadlineDate!.day,
      registrationDeadlineTime!.hour, registrationDeadlineTime!.minute,
    );

    // Validations
    if (end.isBefore(start)) {
      setState(() => isCreating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }
    if (deadline.isAfter(start)) {
      setState(() => isCreating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration deadline must be before the event start time')),
      );
      return;
    }


    try {
      final eventId = await EventService.createEvent(
        title: titleCtrl.text.trim(),
        description: descCtrl.text.trim(),
        category: selectedCategory,
        eventType: selectedEventType,
        location: selectedEventType == 'InPerson' ? locationCtrl.text.trim() : null,
        virtualLink: selectedEventType == 'Online' ? virtualLinkCtrl.text.trim() : null,
        startTime: start,
        endTime: end,
        maxAttendees: int.tryParse(maxAttendeesCtrl.text.trim()),
        registrationDeadline: deadline,
        waitlist: hasWaitlist,
        banner: bannerImage,
      );

      if (eventId != null) {
        if (mounted) {
          Navigator.pop(context, true); // Return true to signal refresh
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create event')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isCreating = false);
    }
  }
}
