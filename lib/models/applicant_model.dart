class Applicant {
  final String id;
  final String applicationId;
  final String name;
  final String? avatarUrl;
  final String headline;
  final String location;
  final String email;
  final String phone;
  final String about;
  final List<String> skills;
  final List<Experience> experience;
  final List<Education> education;
  final String? resumeUrl;
  final String resumeName;
  final String status;
  final String initials;
  final String color;
  
  final DateTime appliedAt;
  final String? submissionUrl;
  final String? submissionInstruction;
  final String? taskReviewStatus;
  final DateTime? submittedAt;
  
  // Temporary debug field
  final Map<String, dynamic> debugJson;

  Applicant({
    required this.id,
    required this.applicationId,
    required this.name,
    required this.avatarUrl,
    required this.headline,
    required this.location,
    required this.email,
    required this.phone,
    required this.about,
    required this.skills,
    required this.experience,
    required this.education,
    this.resumeUrl,
    required this.resumeName,
    required this.status,
    required this.initials,
    required this.color,
    required this.appliedAt,
    this.submissionUrl,
    this.submissionInstruction,
    this.taskReviewStatus,
    this.submittedAt,
    this.debugJson = const {},
  });

  factory Applicant.fromJson(Map<String, dynamic> json) {
    // DEBUG: Log the incoming JSON specific fields
    print("--------------------------------------------------");
    print("DEBUG Applicant ID: ${json['id']}");
    print("DEBUG JSON Keys: ${json.keys.toList()}");
    print("DEBUG submissionUrl (camel): ${json['submissionUrl']}");
    print("DEBUG submission_url (snake): ${json['submission_url']}");
    print("DEBUG screeningResponseUrl: ${json['screeningResponseUrl']}");
    print("DEBUG screening obj: ${json['screening']}");
    print("--------------------------------------------------");

    return Applicant(
      id: json['id']?.toString() ?? '',
      applicationId: json['applicationId']?.toString() ?? '',
      name: json['name'] ?? '',
      avatarUrl: json['avatarUrl'],
      headline: json['headline'] ?? '',
      location: json['location'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      about: json['about'] ?? '',
      skills: (json['skills'] as List? ?? []).map((e) => e.toString()).toList(),
      experience: (json['experience'] as List? ?? [])
          .map((e) => Experience.fromJson(e))
          .toList(),
      education: (json['education'] as List? ?? [])
          .map((e) => Education.fromJson(e))
          .toList(),
      resumeUrl: json['resumeUrl'],
      resumeName: json['resumeName'] ?? 'Resume.pdf',
      status: json['status'] ?? 'Applied',
      initials: json['initials'] ?? '??',
      color: json['color'] ?? 'bg-blue-500',
      appliedAt: DateTime.tryParse(json['appliedAt']?.toString() ?? '') ?? DateTime.now(),
      submissionUrl: _parseSubmissionUrl(json),
      submissionInstruction: _parseSubmissionInstruction(json),
      taskReviewStatus: json['taskReviewStatus'] ?? json['task_review_status'],
      submittedAt: _parseSubmittedAt(json),
      debugJson: json,
    );
  }

  static String? _parseSubmissionUrl(Map<String, dynamic> json) {
    if (json['submissionUrl'] != null) return json['submissionUrl'];
    if (json['submission_url'] != null) return json['submission_url']; // snake_case
    if (json['screeningResponseUrl'] != null) return json['screeningResponseUrl'];
    if (json['screening_response_url'] != null) return json['screening_response_url'];
    
    final screening = json['screening'];
    if (screening != null && screening is Map) {
       return screening['responseUrl'] ?? 
              screening['response_url'] ?? 
              screening['url'] ?? 
              screening['screeningResponseUrl'];
    }
    return null;
  }

  static String? _parseSubmissionInstruction(Map<String, dynamic> json) {
    if (json['submissionInstruction'] != null) return json['submissionInstruction'];
    if (json['submission_instruction'] != null) return json['submission_instruction'];
    if (json['screeningQuestion'] != null) return json['screeningQuestion'];

    final screening = json['screening'];
    if (screening != null && screening is Map) {
       return screening['question'] ?? screening['instruction'] ?? screening['screeningQuestion'];
    }
    return null;
  }
  
  static DateTime? _parseSubmittedAt(Map<String, dynamic> json) {
    if (json['submittedAt'] != null) return DateTime.tryParse(json['submittedAt']);
    if (json['submitted_at'] != null) return DateTime.tryParse(json['submitted_at']);
    
    final screening = json['screening'];
    if (screening != null && screening is Map) {
       if (screening['submittedAt'] != null) return DateTime.tryParse(screening['submittedAt']);
       if (screening['submitted_at'] != null) return DateTime.tryParse(screening['submitted_at']);
    }
    return null;
  }
}

class Experience {
  final String role;
  final String company;
  final String duration;

  Experience({
    required this.role,
    required this.company,
    required this.duration,
  });

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      role: json['role'] ?? '',
      company: json['company'] ?? '',
      duration: json['duration'] ?? '',
    );
  }
}

class Education {
  final String degree;
  final String school;
  final String year;

  Education({
    required this.degree,
    required this.school,
    required this.year,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      degree: json['degree'] ?? '',
      school: json['school'] ?? '',
      year: json['year'] ?? '',
    );
  }
}
