import 'dart:convert';
import 'dart:io';
import 'package:cocpit_app/services/api_client.dart';
import 'package:flutter/cupertino.dart';

class ProfileService {

  /// 🔐 GET LOGGED-IN PROFILE
  /// =========================
  Future<Map<String, dynamic>?> getMyProfile() async {
    try {
      final response = await ApiClient.get("/profile/me");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // optional logging
    }
    return null;
  }

  /// =========================
  /// 🔍 GET ANY USER PROFILE
  /// =========================
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await ApiClient.get("/profile/$userId");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // optional logging
    }
    return null;
  }

  /// ✏️ UPDATE PROFILE
  /// =========================
  Future<bool> updateProfile({
    String? fullName,
    String? headline,
    String? jobTitle,
    String? company,
    String? school,
    String? degree,
    String? location,
    String? about,
  }) async {
    final body = <String, dynamic>{};

    if (fullName != null && fullName.trim().isNotEmpty) {
      body['full_name'] = fullName.trim();
    }

    if (headline != null && headline.trim().isNotEmpty) {
      body['headline'] = headline.trim();
    }

    if (jobTitle != null && jobTitle.trim().isNotEmpty) {
      body['job_title'] = jobTitle.trim();
    }

    if (company != null && company.trim().isNotEmpty) {
      body['company_name'] = company.trim();
    }

    // 🔥 THIS FIXES SCHOOL NOT SAVING
    if (school != null && school.trim().isNotEmpty) {
      body['school'] = school.trim();
    }

    // 🔥 THIS FIXES DEGREE NOT SAVING
    if (degree != null && degree.trim().isNotEmpty) {
      body['degree'] = degree.trim();
    }

    if (location != null && location.trim().isNotEmpty) {
      body['location'] = location.trim();
    }

    if (about != null && about.trim().isNotEmpty) {
      body['about_text'] = about.trim();
    }

    // ✅ If nothing changed, do nothing
    if (body.isEmpty) return true;

    // 🚨 IMPORTANT: correct endpoint
    final response = await ApiClient.put("/profile/me", body: body);

    return response.statusCode == 200;
  }



  /// =========================
  /// 👤 GET IDENTITY
  /// =========================
  Future<Map<String, dynamic>?> getIdentity() async {
    try {
      final response = await ApiClient.get("/profile/identity");
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  /// =========================
  /// ✏️ UPDATE IDENTITY
  /// =========================
  Future<bool> updateIdentity({
    required String openTo,
    required String availability,
    required String preference,
  }) async {
    try {
      final response = await ApiClient.put(
        "/profile/identity",
        body: {
          "open_to": openTo,
          "availability": availability,
          "work_preference": preference,
        },
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// =========================
  /// 🖼️ UPLOAD / REPLACE AVATAR
  /// =========================
  Future<bool> uploadAvatar(File image) async {
    final response = await ApiClient.multipart(
      "/profile/avatar",
      fileField: "avatar",
      file: image,
    );

    return response.statusCode == 200;
  }

  /// =========================
  /// 🖼️ UPLOAD / REPLACE COVER IMAGE
  /// =========================
  Future<bool> uploadCover(File image) async {
    final response = await ApiClient.multipart(
      "/profile/cover",
      fileField: "cover",
      file: image,
    );

    return response.statusCode == 200;
  }

  /// =========================
  /// 🧑‍💼 EXPERIENCE
  /// =========================
  Future<bool> addExperience({
    required String title,
    required String company,
    required String location,
    required String startDate,
    String? endDate,
    required bool currentlyWorking,
    required String description,
  }) async {
    final response = await ApiClient.post(
      "/profile/experiences",
      body: {
        "title": title.trim(),
        "company_name": company.trim(),
        "location": location.trim(),
        "start_date": startDate,
        "end_date": currentlyWorking ? null : endDate,
        "is_current": currentlyWorking,
        "description": description.trim(),
      },
    );

    return response.statusCode == 201;
  }

  Future<bool> updateExperience({
    required String id,
    required String title,
    required String company,
    required String location,
    required String startDate,
    String? endDate,
    required bool isCurrent,
    required String description,
  }) async {
    final response = await ApiClient.put(
      "/profile/experiences/$id",
      body: {
        "title": title.trim(),
        "company_name": company.trim(),
        "location": location.trim(),
        "start_date": startDate,
        "end_date": isCurrent ? null : endDate,
        "is_current": isCurrent,
        "description": description.trim(),
      },
    );

    return response.statusCode == 200;
  }

  Future<bool> deleteExperience(String id) async {
    final response = await ApiClient.delete("/profile/experiences/$id");
    return response.statusCode == 200;
  }

  /// =========================
  /// 🎓 EDUCATION
  /// =========================
  Future<bool> addEducation({
    required String school,
    required String degree,
    required String fieldOfStudy,
    required String startDate,
    String? endDate,
    required String description,
  }) async {
    final response = await ApiClient.post(
      "/profile/educations",
      body: {
        "school_name": school.trim(),
        "degree": degree.trim(),
        "field_of_study": fieldOfStudy.trim(),
        "start_date": startDate,
        "end_date": endDate,
        "description": description.trim(),
      },
    );

    return response.statusCode == 201;
  }

  Future<bool> updateEducation({
    required String id,
    required String school,
    required String degree,
    required String fieldOfStudy,
    required String startDate,
    String? endDate,
    required String description,
  }) async {
    final response = await ApiClient.put(
      "/profile/educations/$id",
      body: {
        "school_name": school.trim(),
        "degree": degree.trim(),
        "field_of_study": fieldOfStudy.trim(),
        "start_date": startDate,
        "end_date": endDate,
        "description": description.trim(),
      },
    );

    return response.statusCode == 200;
  }

  Future<bool> deleteEducation(String id) async {
    final response = await ApiClient.delete("/profile/educations/$id");
    return response.statusCode == 200;
  }

  /// =========================
  /// 🧠 SKILLS
  /// =========================
  Future<bool> addSkills(List<String> names) async {
    if (names.isEmpty) return true;

    final response = await ApiClient.post(
      "/profile/skills",
      body: {
        "name": names.map((e) => e.trim()).toList(),
      },
    );

    return response.statusCode == 201;
  }

  Future<bool> updateSkill(String skillId, String name) async {
    final response = await ApiClient.put(
      "/profile/skills/$skillId",
      body: {"name": name.trim()},
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteSkill(String skillId) async {
    final response = await ApiClient.delete("/profile/skills/$skillId");
    return response.statusCode == 200;
  }

  /// =========================
  /// 🔗 CONNECTIONS
  /// =========================
  Future<int> getConnectionCount(String userId) async {
    try {
      final response =
      await ApiClient.get("/users/$userId/connections/count");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final rawCount = data['connection_count'];

        final count = rawCount is int
            ? rawCount
            : int.tryParse(rawCount.toString()) ?? 0;

        debugPrint("Parsed connection count = $count");

        return count;
      }
    } catch (e) {
      debugPrint("getConnectionCount error: $e");
    }

    return 0;
  }

}
