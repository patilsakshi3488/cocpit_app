import 'package:intl/intl.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String eventType; // 'Online' or 'InPerson'
  final String? location;
  final String? virtualLink;
  final DateTime startTimeDt;
  final DateTime endTimeDt;
  final String? bannerUrl;
  final int? maxAttendees;
  final bool waitlistEnabled;
  final DateTime registrationDeadline;
  final String organizerId;
  final String? organizerName;
  int registeredCount; // Mutable for UI optimistic updates

  // Frontend helper properties
  bool isRegistered;
  bool isSaved;
  bool createdByMe;

  // Extra fields to support UI creation flow if needed (though we should prefer mapped fields)
  // For CreateEventScreen compatibility until refactored:
  final String _category;
  final bool _isFree;

  EventModel({
    this.id = '', // Default for new events
    required this.title,
    required this.description,
    required this.eventType,
    this.location,
    this.virtualLink,
    required this.startTimeDt,
    required this.endTimeDt,
    this.bannerUrl,
    this.maxAttendees,
    required this.waitlistEnabled,
    required this.registrationDeadline,
    this.organizerId = '',
    this.organizerName,
    this.registeredCount = 0,
    this.isRegistered = false,
    this.isSaved = false,
    this.createdByMe = false,
    String category = 'General',
    bool isFree = true,
  }) : _category = category, _isFree = isFree;

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['event_id'].toString(),
      title: json['title'],
      description: json['description'],
      eventType: json['event_type'],
      location: json['location'],
      virtualLink: json['virtual_link'],
      startTimeDt: DateTime.parse(json['start_time']),
      endTimeDt: DateTime.parse(json['end_time']),
      bannerUrl: json['banner_url'],
      maxAttendees: json['max_attendees'] != null ? int.tryParse(json['max_attendees'].toString()) : null,
      waitlistEnabled: json['waitlist_enabled'] ?? false,
      registrationDeadline: DateTime.parse(json['registration_deadline']),
      organizerId: json['organizer_id'].toString(),
      organizerName: json['organizer_name'],
      registeredCount: json['registered_count'] != null ? int.parse(json['registered_count'].toString()) : 0,
      isRegistered: json['isRegistered'] ?? false,
      isSaved: json['isSaved'] ?? false,
      createdByMe: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': id,
      'title': title,
      'description': description,
      'event_type': eventType,
      'location': location,
      'virtual_link': virtualLink,
      'start_time': startTimeDt.toIso8601String(),
      'end_time': endTimeDt.toIso8601String(),
      'banner_url': bannerUrl,
      'max_attendees': maxAttendees,
      'waitlist_enabled': waitlistEnabled,
      'registration_deadline': registrationDeadline.toIso8601String(),
      'organizer_id': organizerId,
      'organizer_name': organizerName,
      'registered_count': registeredCount,
      'isRegistered': isRegistered,
      'isSaved': isSaved,
    };
  }

  // Helper Getters for UI compatibility
  String get image => bannerUrl != null && bannerUrl!.isNotEmpty
      ? bannerUrl!
      : 'lib/images/event_placeholder.jpg';

  String get category => _category;

  bool get isFree => _isFree;

  int get totalRegistrations => registeredCount;
  set totalRegistrations(int val) => registeredCount = val;

  // Date/Time formatters
  String get startDate => DateFormat('d MMM').format(startTimeDt).toUpperCase();
  String get startTime => DateFormat('HH:mm').format(startTimeDt);
  String get endDate => DateFormat('d MMM').format(endTimeDt).toUpperCase();
  String get endTime => DateFormat('HH:mm').format(endTimeDt);

  // CopyWith for optimistic updates
  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? eventType,
    String? location,
    String? virtualLink,
    DateTime? startTimeDt,
    DateTime? endTimeDt,
    String? bannerUrl,
    int? maxAttendees,
    bool? waitlistEnabled,
    DateTime? registrationDeadline,
    String? organizerId,
    String? organizerName,
    int? registeredCount,
    bool? isRegistered,
    bool? isSaved,
    bool? createdByMe,
    String? category,
    bool? isFree,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventType: eventType ?? this.eventType,
      location: location ?? this.location,
      virtualLink: virtualLink ?? this.virtualLink,
      startTimeDt: startTimeDt ?? this.startTimeDt,
      endTimeDt: endTimeDt ?? this.endTimeDt,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      waitlistEnabled: waitlistEnabled ?? this.waitlistEnabled,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      registeredCount: registeredCount ?? this.registeredCount,
      isRegistered: isRegistered ?? this.isRegistered,
      isSaved: isSaved ?? this.isSaved,
      createdByMe: createdByMe ?? this.createdByMe,
      category: category ?? this._category,
      isFree: isFree ?? this._isFree,
    );
  }
}
