class Job {
  final String id;
  final String recruiterId;
  final String title;
  final String companyName;
  final String location;
  final String description;
  final int salaryMin;
  final int salaryMax;
  final String jobType;
  final String workMode;
  final String companyType;
  final String experienceLevel;
  final String aboutCompany;
  final String industry;
  final bool easyApply;
  final bool activelyHiring;
  final DateTime createdAt;
  final String? recruiterName;
  final int applicantCount;

  // UI State fields (mutable as they can change)
  bool isSaved;
  bool hasApplied;
  String? applicationStatus;
  String? applicationId;
  
  // Task Assignment fields
  bool taskAssigned;
  String? taskType;
  String? taskInstruction;

  // Applicant Submission fields
  String? submissionUrl;
  String? submissionType;
  DateTime? submissionDate;

  Job({
    required this.id,
    required this.recruiterId,
    required this.title,
    required this.companyName,
    required this.location,
    required this.description,
    required this.salaryMin,
    required this.salaryMax,
    required this.jobType,
    required this.workMode,
    required this.companyType,
    required this.experienceLevel,
    required this.aboutCompany,
    required this.industry,
    required this.easyApply,
    required this.activelyHiring,
    required this.createdAt,
    this.recruiterName,
    this.applicantCount = 0,
    this.isSaved = false,
    this.hasApplied = false,
    this.applicationStatus,
    this.taskAssigned = false,
    this.taskType,
    this.taskInstruction,
    this.submissionUrl,
    this.submissionType,
    this.submissionDate,
    this.applicationId,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['job_id']?.toString() ?? json['_id']?.toString() ?? json['id']?.toString() ?? '',
      recruiterId: json['recruiter_id']?.toString() ?? '',
      title: json['title'] ?? '',
      companyName: json['company_name'] ?? '',
      location: json['location'] ?? '',
      description: json['description'] ?? '',
      salaryMin: _parseInt(json['salary_min'] ?? json['minSalary']),
      salaryMax: _parseInt(json['salary_max'] ?? json['maxSalary']),
      jobType: json['job_type'] ?? '',
      workMode: json['work_mode'] ?? '',
      companyType: json['company_type'] ?? '',
      experienceLevel: json['experience_level'] ?? '',
      aboutCompany: json['about_company'] ?? '',
      industry: json['industry'] ?? '',
      easyApply: json['easy_apply'] == true,
      activelyHiring: json['actively_hiring'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      recruiterName: json['recruiter_name'],
      applicantCount: _parseInt(json['applicant_count'] ?? json['applicants'] ?? json['applicants_count']),
      isSaved: json['isSaved'] == true,
      hasApplied: json['hasApplied'] == true,
      applicationStatus: json['applicationStatus'] ?? json['application_status'],
      applicationId: json['application_id']?.toString() ?? json['applicationId']?.toString() ?? (json['application'] is Map ? json['application']['_id']?.toString() : null),
      taskAssigned: json['task_assigned'] == true || json['taskAssigned'] == true || json['screeningRequired'] == true || json['screening_required'] == true,
      taskType: json['task_type'] ?? json['taskType'] ?? json['screeningType'] ?? json['screening_type'],
      taskInstruction: json['task_instruction'] ?? 
                      json['taskInstruction'] ?? 
                      json['instruction'] ?? 
                      json['submission_instruction'] ?? 
                      json['submissionInstruction'] ?? 
                      json['question'] ??
                      json['screeningQuestion'] ??
                      json['screening_question'] ??
                      (json['task'] is Map ? (json['task']['instruction'] ?? json['task']['description'] ?? json['task']['question']) : null),
      submissionUrl: json['submission_url'] ?? json['submissionUrl'],
      submissionType: json['submission_type'] ?? json['submissionType'],
      submissionDate: DateTime.tryParse(json['submission_date']?.toString() ?? json['submissionDate']?.toString() ?? ''),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  String get salaryRange {
    if (salaryMin == 0 && salaryMax == 0) return "Negotiable";
    final min = (salaryMin / 1000).toStringAsFixed(0);
    final max = (salaryMax / 1000).toStringAsFixed(0);
    return "\$${min}k - \$${max}k";
  }

  String get postedTimeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 30) return "${(diff.inDays / 30).floor()}mo ago";
    if (diff.inDays > 0) return "${diff.inDays}d ago";
    if (diff.inHours > 0) return "${diff.inHours}h ago";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m ago";
    return "Just now";
  }

  String get initials {
    if (companyName.isEmpty) return "?";
    return companyName[0].toUpperCase();
  }
}
