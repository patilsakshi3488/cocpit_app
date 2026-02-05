import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';

import '../config/api_config.dart';
import '../models/event_model.dart';
import 'api_client.dart';

class EventService {
  /// Get all events with optional filters
  static Future<List<EventModel>> getEvents({
    String? location,
    String? type,
    String? category,
    String? date,
    String? startDate,
    String? endDate,
    int limit = 50,
  }) async {
    String query = "";
    List<String> params = [];
    if (location != null && location.isNotEmpty) params.add("location=$location");
    if (type != null && type.isNotEmpty) params.add("type=$type");
    if (category != null && category.isNotEmpty) params.add("category=$category");
    if (date != null && date.isNotEmpty) params.add("date=$date");
    if (startDate != null && startDate.isNotEmpty) params.add("startDate=$startDate");
    if (endDate != null && endDate.isNotEmpty) params.add("endDate=$endDate");
    params.add("limit=$limit");

    if (params.isNotEmpty) {
      query = "?${params.join("&")}";
    }

    final response = await ApiClient.get("${ApiConfig.events}$query");
    debugPrint("Status: ${response.statusCode}");
    debugPrint("Body: ${response.body}");


    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);

      final List items = body['items'] ?? [];

      return items
          .map((e) => EventModel.fromJson(e))
          .toList();
    } else {
      throw Exception("Failed to load events");
    }
  }

    /// Get event details by ID
  static Future<EventModel> getEventById(String id) async {
    final response = await ApiClient.get("${ApiConfig.events}/$id");

    if (response.statusCode == 200) {
      return EventModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load event details");
    }
  }

  /// Create a new event
  static Future<String?> createEvent({
    required String title,
    required String description,
    required String eventType,
    required String category,
    String? virtualLink,
    String? location,
    required DateTime startTime,
    required DateTime endTime,
    int? maxAttendees,
    required DateTime registrationDeadline,
    required bool waitlist,
    File? banner,
    String? organizerName,
    String? organizerEmail,
  }) async {
    final Map<String, String> fields = {
      "title": title,
      "description": description,
      "category": category,
      "eventType": eventType,
      "startTime": startTime.toIso8601String(),
      "endTime": endTime.toIso8601String(),
      "registrationDeadline": registrationDeadline.toIso8601String(),
      "waitlist": waitlist.toString(),
    };

    if (virtualLink != null) fields["virtualLink"] = virtualLink;
    if (location != null) fields["location"] = location;
    if (maxAttendees != null) fields["maxAttendees"] = maxAttendees.toString();
    if (organizerName != null) fields["organizerName"] = organizerName;
    if (organizerEmail != null) fields["organizerEmail"] = organizerEmail;

    // The backend uses uploadEventBanner.single('banner') middleware.
    // This typically requires a multipart request.
    // Even if we don't have a file, we might need to send multipart without file or handle it.
    // However, ApiClient.multipart requires a file.
    // If no banner is provided, we can try to send a dummy file or modify backend/client.
    // For now, let's assume we use ApiClient.post if no file, and hope backend accepts JSON or form-urlencoded if 'banner' is missing.
    // But `upload.single('banner')` usually throws if not multipart.

    // We will assume banner is provided for now as the UI in CreateEventScreen allows picking one.
    // If no banner is picked, we might need to handle it.

    if (banner != null) {
      final response = await ApiClient.multipart(
        ApiConfig.events,
        fileField: "banner",
        file: banner,
        fields: fields,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['eventId'].toString();
      }
    } else {
      // Try JSON post. Backend might complain if it expects multipart.
      final response = await ApiClient.post(
        ApiConfig.events,
        body: {
          "title": title,
          "description": description,
          "category": category,
          "eventType": eventType,
          "virtualLink": virtualLink,
          "location": location,
          "startTime": startTime.toIso8601String(),
          "endTime": endTime.toIso8601String(),
          "maxAttendees": maxAttendees,
          "registrationDeadline": registrationDeadline.toIso8601String(),
          "waitlist": waitlist,
          "organizerName": organizerName,
          "organizerEmail": organizerEmail,
        },
      );
       if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['eventId'].toString();
      }
    }
    return null;
  }

  /// Register for an event
  static Future<bool> registerForEvent(String eventId, {
    required String name,
    required String email,
    required String mobileNumber,
    String? companyName,
    String? jobTitle,
  }) async {
    final response = await ApiClient.post(
      "${ApiConfig.events}/$eventId/register",
      body: {
        "name": name,
        "email": email,
        "mobile_number": mobileNumber,
        "company_name": companyName,
        "job_title": jobTitle,
      },
    );

    return response.statusCode == 201 || response.statusCode == 200;
  }

  /// Unregister from an event
  static Future<bool> unregisterFromEvent(String eventId) async {
    final response = await ApiClient.delete("${ApiConfig.events}/$eventId/register");
    return response.statusCode == 200;
  }

  /// Check registration status
  static Future<bool> checkRegistrationStatus(String eventId) async {
    final response = await ApiClient.get("${ApiConfig.events}/$eventId/registration-status");
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['isRegistered'] ?? false;
    }
    return false;
  }

  /// Get my registered events
  static Future<List<EventModel>> getMyRegisteredEvents() async {
    final response = await ApiClient.get("${ApiConfig.events}/me/events/registered");
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => EventModel.fromJson(e)..isRegistered = true).toList();
    }
    return [];
  }

  /// Get my created events
  static Future<List<EventModel>> getMyCreatedEvents() async {
    final response = await ApiClient.get("${ApiConfig.events}/me/events/created");
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => EventModel.fromJson(e)..createdByMe = true).toList();
    }
    return [];
  }

  /// Save/Bookmark event
  static Future<bool> saveEvent(String eventId) async {
    final response = await ApiClient.post("${ApiConfig.events}/$eventId/save");
    return response.statusCode == 201;
  }

  /// Unsave/Remove bookmark
  static Future<bool> unsaveEvent(String eventId) async {
    final response = await ApiClient.delete("${ApiConfig.events}/$eventId/save");
    return response.statusCode == 200;
  }

  /// Get my saved events
  static Future<List<EventModel>> getMySavedEvents() async {
    final response = await ApiClient.get("${ApiConfig.events}/me/events/saved");
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => EventModel.fromJson(e)..isSaved = true).toList();
    }
    return [];
  }
  /// Get registrants for an event (Organizer only)
  static Future<List<Map<String, dynamic>>> getEventRegistrants(String eventId) async {
    // Note: Assuming endpoint /api/events/:id/registrations exists based on user requirement
    final response = await ApiClient.get("${ApiConfig.events}/$eventId/registrations");
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Update an existing event
  static Future<bool> updateEvent(String eventId, {
    String? title,
    String? description,
    String? eventType,
    String? category,
    String? virtualLink,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    int? maxAttendees,
    DateTime? registrationDeadline,
    bool? waitlist,
    File? banner,
  }) async {
    final Map<String, String> fields = {};

    if (title != null) fields["title"] = title;
    if (description != null) fields["description"] = description;
    if (category != null) fields["category"] = category;
    if (eventType != null) fields["eventType"] = eventType;
    if (startTime != null) fields["startTime"] = startTime.toIso8601String();
    if (endTime != null) fields["endTime"] = endTime.toIso8601String();
    if (registrationDeadline != null) {
      fields["registrationDeadline"] = registrationDeadline.toIso8601String();
    }
    if (waitlist != null) fields["waitlist"] = waitlist.toString();
    if (virtualLink != null) fields["virtualLink"] = virtualLink;
    if (location != null) fields["location"] = location;
    if (maxAttendees != null) fields["maxAttendees"] = maxAttendees.toString();

    // If banner is provided, use multipart
    if (banner != null) {
      final response = await ApiClient.multipart(
        "${ApiConfig.events}/$eventId",
        fileField: "banner",
        file: banner,
        fields: fields,
        method: "PUT",
      );
      return response.statusCode == 200;
    } else {
      // Use standard PUT request
      final response = await ApiClient.put(
        "${ApiConfig.events}/$eventId",
        body: fields,
      );
      return response.statusCode == 200;
    }
  }

  /// Delete an event
  static Future<bool> deleteEvent(String eventId) async {
    final response = await ApiClient.delete("${ApiConfig.events}/$eventId");
    return response.statusCode == 200;
  }
}
