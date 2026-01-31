import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';

import '../config/api_config.dart';
import 'api_client.dart';
import '../models/job_model.dart';
import '../models/applicant_model.dart';

class JobService {
  Future<List<Job>> getAllJobs({
    String? title,
    String? location,
    bool? easyApply,
    bool? activelyHiring,
    String? experienceLevel,
    int? minSalary,
    int? maxSalary,
    String? datePosted,
    String? jobType,
    String? workMode,
    String? companyType,
    String? industry,
  }) async {
    final params = _buildQueryParams({
      'title': title,
      'location': location,
      'easyApply': easyApply?.toString(),
      'activelyHiring': activelyHiring?.toString(),
      'experienceLevel': experienceLevel,
      'minSalary': minSalary?.toString(),
      'maxSalary': maxSalary?.toString(),
      'datePosted': datePosted,
      'jobType': jobType,
      'workMode': workMode,
      'companyType': companyType,
      'industry': industry,
    });

    final response = await ApiClient.get("${ApiConfig.jobs}$params");

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Job.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load jobs");
    }
  }

  Future<List<Job>> getJobOffers() async {
    final response = await ApiClient.get(ApiConfig.jobOffers);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Job.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load job offers");
    }
  }

  Future<Map<String, int>> getDashboardStats() async {
    final response = await ApiClient.get(ApiConfig.jobStats);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'totalJobs': data['totalJobs'] ?? 0,
        'activeJobs': data['activeJobs'] ?? 0,
        'totalApplicants': data['totalApplicants'] ?? 0,
      };
    } else {
      throw Exception("Failed to load stats");
    }
  }

  Future<List<Job>> getMyApplications({String? status}) async {
    String path = ApiConfig.myApplications;
    if (status != null) {
      path += "?status=$status";
    }
    final response = await ApiClient.get(path);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Job.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load applications");
    }
  }

  Future<List<Job>> getMySavedJobs() async {
    final response = await ApiClient.get(ApiConfig.mySavedJobs);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Job.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load saved jobs");
    }
  }

  Future<List<Job>> getMyJobs() async {
    final response = await ApiClient.get(ApiConfig.myPostedJobs);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Job.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load posted jobs");
    }
  }

  Future<List<Applicant>> getJobApplicants(String jobId) async {
    final response = await ApiClient.get("${ApiConfig.jobs}/$jobId/applicants");

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Applicant.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load applicants");
    }
  }



  Future<void> createJob(Map<String, dynamic> jobData) async {
    final response = await ApiClient.post(
      ApiConfig.jobs,
      body: jobData,
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return; // ✅ success
    }

    // ❌ FAILURE — parse backend error
    try {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to create job');
    } catch (_) {
      throw Exception('Failed to create job');
    }
  }


  Future<bool> applyJob({
    required String jobId,
    required String fullName,
    required String email,
    required String phone,
    String? coverNote,
    required File resumeFile,
  }) async {
    final response = await ApiClient.multipart(
      "${ApiConfig.jobs}/$jobId/apply",
      fileField: "resume",
      file: resumeFile,
      fields: {
        "full_name": fullName,
        "email": email,
        "phone": phone,
        if (coverNote != null) "cover_note": coverNote,
      },
    );
    if (response.statusCode != 201) {
      throw Exception("Failed to apply for job: ${response.body}");
    }
    return response.statusCode == 201 ;

  }

  Future<void> saveJob(String jobId) async {
    final response = await ApiClient.post("${ApiConfig.jobs}/$jobId/save");
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception("Failed to save job");
    }
  }

  Future<void> unsaveJob(String jobId) async {
    final response = await ApiClient.delete("${ApiConfig.jobs}/$jobId/save");
    if (response.statusCode != 200) {
      throw Exception("Failed to unsave job");
    }
  }

  String _buildQueryParams(Map<String, String?> params) {
    final validParams = <String, String>{};
    params.forEach((key, value) {
      if (value != null && value.isNotEmpty) {
        validParams[key] = value;
      }
    });

    if (validParams.isEmpty) return "";

    return "?" + validParams.entries.map((e) => "${e.key}=${Uri.encodeComponent(e.value)}").join("&");
  }
}
