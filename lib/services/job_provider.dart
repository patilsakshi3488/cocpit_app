import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/job_model.dart';
import '../models/applicant_model.dart';
import 'job_service.dart';


class JobProvider extends ChangeNotifier {
  final JobService _jobService = JobService();

  List<Job> _allJobs = [];
  List<Job> _jobOffers = [];
  List<Job> _myApplications = [];
  List<Job> _mySavedJobs = [];
  List<Job> _myPostedJobs = [];
  Map<String, int> _dashboardStats = {};

  bool _isLoadingJobs = false;
  bool _isLoadingOffers = false;
  bool _isLoadingMyApps = false;
  bool _isLoadingSaved = false;
  bool _isLoadingPosted = false;
  bool _isLoadingStats = false;

  String? _error;

  // Getters
  List<Job> get allJobs => _allJobs;
  List<Job> get jobOffers => _jobOffers;
  List<Job> get myApplications => _myApplications;
  List<Job> get mySavedJobs => _mySavedJobs;
  List<Job> get myPostedJobs => _myPostedJobs;
  Map<String, int> get dashboardStats => _dashboardStats;

  bool get isLoadingJobs => _isLoadingJobs;
  bool get isLoadingOffers => _isLoadingOffers;
  bool get isLoadingMyApps => _isLoadingMyApps;
  bool get isLoadingSaved => _isLoadingSaved;
  bool get isLoadingPosted => _isLoadingPosted;
  bool get isLoadingStats => _isLoadingStats;

  String? get error => _error;

  // Fetch Methods

  Future<void> fetchJobs({
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
    _isLoadingJobs = true;
    _error = null;
    notifyListeners();

    try {
      _allJobs = await _jobService.getAllJobs(
        title: title,
        location: location,
        easyApply: easyApply,
        activelyHiring: activelyHiring,
        experienceLevel: experienceLevel,
        minSalary: minSalary,
        maxSalary: maxSalary,
        datePosted: datePosted,
        jobType: jobType,
        workMode: workMode,
        companyType: companyType,
        industry: industry,
      );
    } catch (e) {
      _error = e.toString();
      debugPrint("Error fetching jobs: $e");
    } finally {
      _isLoadingJobs = false;
      notifyListeners();
    }
  }

  Future<void> fetchJobOffers() async {
    _isLoadingOffers = true;
    notifyListeners();

    try {
      _jobOffers = await _jobService.getJobOffers();
    } catch (e) {
      debugPrint("Error fetching offers: $e");
    } finally {
      _isLoadingOffers = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyApplications({String? status}) async {
    _isLoadingMyApps = true;
    notifyListeners();

    try {
      _myApplications = await _jobService.getMyApplications(status: status);

      // Simulation removed to fetch real data from backend
    } catch (e) {
      debugPrint("Error fetching applications: $e");
    } finally {
      
      
      _isLoadingMyApps = false;
      notifyListeners();
    }
  }

  Future<void> fetchMySavedJobs() async {
    _isLoadingSaved = true;
    notifyListeners();

    try {
      _mySavedJobs = await _jobService.getMySavedJobs();
    } catch (e) {
      debugPrint("Error fetching saved jobs: $e");
    } finally {
      _isLoadingSaved = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyPostedJobs() async {
    _isLoadingPosted = true;
    notifyListeners();

    try {
      _myPostedJobs = await _jobService.getMyJobs();
    } catch (e) {
      debugPrint("Error fetching posted jobs: $e");
    } finally {
      _isLoadingPosted = false;
      notifyListeners();
    }
  }

  Future<void> fetchDashboardStats() async {
    _isLoadingStats = true;
    notifyListeners();

    try {
      _dashboardStats = await _jobService.getDashboardStats();
    } catch (e) {
      debugPrint("Error fetching stats: $e");
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  Future<List<Applicant>> fetchJobApplicants(String jobId) async {
    try {
      return await _jobService.getJobApplicants(jobId);
    } catch (e) {
      debugPrint("Error fetching applicants: $e");
      rethrow;
    }
  }

  Future<void> fetchJobDetails(String jobId) async {
    try {
      final updatedJob = await _jobService.getJobById(jobId);
      
      // Update local lists with the new job details
      void updateList(List<Job> list) {
        final index = list.indexWhere((j) => j.id == jobId);
        if (index != -1) {
          list[index] = updatedJob;
        }
      }

      updateList(_allJobs);
      updateList(_jobOffers);
      updateList(_myApplications);
      updateList(_mySavedJobs);
      updateList(_myPostedJobs);
      
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching job details: $e");
      // Don't rethrow necessarily, just log
    }
  }

  // Actions

  Future<void> createJob(Map<String, dynamic> jobData) async {
    try {
      await _jobService.createJob(jobData);
      fetchMyPostedJobs(); // Refresh posted jobs
      fetchJobs(); // Refresh all jobs
    } catch (e) {
      rethrow;
    }
  }

  Future<void> applyJob({
    required String jobId,
    required String fullName,
    required String email,
    required String phone,
    String? coverNote,
    File? resumeFile,
    String? resumeUrl,
  }) async {
    try {
      await _jobService.applyJob(
        jobId: jobId,
        fullName: fullName,
        email: email,
        phone: phone,
        coverNote: coverNote,
        resumeFile: resumeFile,
        resumeUrl: resumeUrl,
      );

      // Update local state to reflect application
      _updateLocalJobStatus(jobId, hasApplied: true);
      fetchMyApplications();

      fetchMyApplications();

    } catch (e) {
      rethrow;
    }
  }

  Future<void> submitTask({
    required String applicationId,
    File? file,
    String? url,
  }) async {
    try {
      await _jobService.submitTask(
        applicationId: applicationId,
        file: file,
        url: url,
      );
      // Refresh applications to update status locally if needed
      // Or just notify listeners if we want to update UI immediately
      fetchMyApplications();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleSaveJob(String jobId, bool currentStatus) async {
    // Optimistic Update
    _updateLocalJobStatus(jobId, isSaved: !currentStatus);
    notifyListeners();

    try {
      if (currentStatus) {
        // Was saved, so unsave
        await _jobService.unsaveJob(jobId);
      } else {
        // Was not saved, so save
        await _jobService.saveJob(jobId);
      }
      // Refresh saved jobs list silently
      _jobService.getMySavedJobs().then((jobs) {
        _mySavedJobs = jobs;
        notifyListeners();
      });
    } catch (e) {
      // Revert on error
      _updateLocalJobStatus(jobId, isSaved: currentStatus);
      notifyListeners();
      debugPrint("Error toggling save: $e");
      rethrow;
    }
  }

  void markJobAsApplied(String jobId) {
    _updateLocalJobStatus(jobId, hasApplied: true);
    notifyListeners();
  }

  void _updateLocalJobStatus(String jobId, {bool? isSaved, bool? hasApplied}) {
    // ... existing implementation ...
    void updateList(List<Job> list) {
      for (var job in list) {
        if (job.id == jobId) {
          if (isSaved != null) job.isSaved = isSaved;
          if (hasApplied != null) {
             job.hasApplied = hasApplied;
             job.applicationStatus = "Applied";
          }
        }
      }
    }

    updateList(_allJobs);
    updateList(_jobOffers);
    updateList(_myApplications);
    updateList(_mySavedJobs);
    updateList(_myPostedJobs);
  }

  Future<void> updateApplicationStatus(String applicationId, String status, {Map<String, dynamic>? screening}) async {
    try {
      await _jobService.updateApplicationStatus(applicationId, status, screening: screening);
      // We might want to refresh applicants list if we have the jobId context
      // But we don't have jobId here easily unless we pass it or store it.
      // For now, caller should refresh.
    } catch (e) {
      rethrow;
    }
  }
}
