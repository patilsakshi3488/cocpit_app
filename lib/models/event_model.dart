class EventModel {
  final String id;
  final String title;
  final String description;
  final String eventType; // 'Online' or 'InPerson'
  final String? location;
  final String? virtualLink;
  final DateTime startTime;
  final DateTime endTime;
  final String? bannerUrl;
  final int? maxAttendees;
  final bool waitlistEnabled;
  final DateTime registrationDeadline;
  final String organizerId;
  final String? organizerName;
  final int registeredCount;

  // Frontend helper properties
  bool isRegistered;
  bool isSaved;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.eventType,
    this.location,
    this.virtualLink,
    required this.startTime,
    required this.endTime,
    this.bannerUrl,
    this.maxAttendees,
    required this.waitlistEnabled,
    required this.registrationDeadline,
    required this.organizerId,
    this.organizerName,
    this.registeredCount = 0,
    this.isRegistered = false,
    this.isSaved = false,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['event_id'].toString(),
      title: json['title'],
      description: json['description'],
      eventType: json['event_type'],
      location: json['location'],
      virtualLink: json['virtual_link'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      bannerUrl: json['banner_url'],
      maxAttendees: json['max_attendees'] != null ? int.tryParse(json['max_attendees'].toString()) : null,
      waitlistEnabled: json['waitlist_enabled'] ?? false,
      registrationDeadline: DateTime.parse(json['registration_deadline']),
      organizerId: json['organizer_id'].toString(),
      organizerName: json['organizer_name'],
      registeredCount: json['registered_count'] != null ? int.parse(json['registered_count'].toString()) : 0,
      // Helper fields might need to be set separately or from specific API responses
      isRegistered: json['isRegistered'] ?? false,
      isSaved: json['isSaved'] ?? false,
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
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
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
}
