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
  });

  factory Applicant.fromJson(Map<String, dynamic> json) {
    return Applicant(
      id: json['id']?.toString() ?? '',
      applicationId: json['applicationId']?.toString() ?? '',
      name: json['name'] ?? '',
      avatarUrl:json['avatarUrl'],
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
    );
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
