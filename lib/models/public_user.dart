class PublicUser {
  final String id;
  final String fullName;
  final String? headline;
  final String? avatarUrl;
  final String? coverImageUrl;
  final String? location;
  final String? about;

  final List<PublicExperience> experiences;
  final List<PublicEducation> educations;
  final List<String> skills;
  final bool? isFollowing;
  final String? resumeUrl;
  final String? email;
  final String? mobileNumber;

  PublicUser({
    required this.id,
    required this.fullName,
    this.headline,
    this.avatarUrl,
    this.coverImageUrl,
    this.location,
    this.about,
    required this.experiences,
    required this.educations,
    required this.skills,
    this.isFollowing,
    this.resumeUrl,
    this.email,
    this.mobileNumber,
  });

  factory PublicUser.fromJson(Map<String, dynamic> json) {
    // Handle nested 'user' object if present (common in our API responses)
    final userData = json['user'] ?? json;

    try {
      final id =
          userData['id']?.toString() ?? userData['user_id']?.toString() ?? '';

      // Allow 'name' or 'full_name'
      final fullName =
          userData['full_name'] ?? userData['name'] ?? 'Unknown User';

      final headline = userData['headline'];
      final avatarUrl = userData['avatar'] ?? userData['avatar_url'];
      final coverImageUrl =
          userData['cover_image'] ??
          userData['cover_image_url'] ??
          userData['cover_url'];
      final location = userData['location'];
      final about = userData['about'] ?? userData['about_text'];

      final experiencesList =
          userData['experiences'] ?? json['experiences'] ?? [];
      final experiences = (experiencesList as List)
          .map((e) => PublicExperience.fromJson(e))
          .toList();

      final educationsList = userData['educations'] ?? json['educations'] ?? [];
      final educations = (educationsList as List)
          .map((e) => PublicEducation.fromJson(e))
          .toList();

      final skillsList = userData['skills'] ?? json['skills'] ?? [];
      final skills = List<String>.from(skillsList);

      final isFollowing = userData['is_following'] ?? json['is_following'];
      
      // Parse Resume
      final resumeObj = userData['resume'] ?? json['resume'];
      String? resumeUrl;
      
      if (resumeObj != null) {
        if (resumeObj is Map) {
           resumeUrl = resumeObj['url'] ?? resumeObj['file_url'];
        } else if (resumeObj is String) {
           resumeUrl = resumeObj;
        }
      }

      // Fallback: Check common flat keys if not found in 'resume' object
      resumeUrl ??= userData['resume_url'] ?? 
                    json['resume_url'] ?? // Check root json
                    userData['resume_file'] ??
                    json['resume_file'] ?? // Check root json
                    userData['cv'] ??
                    json['cv'] ?? // Check root json
                    userData['cv_url'] ??
                    userData['document_url'];

      return PublicUser(
        id: id,
        fullName: fullName,
        headline: headline,
        avatarUrl: avatarUrl,
        coverImageUrl: coverImageUrl,
        location: location,
        about: about,
        experiences: experiences,
        educations: educations,
        skills: skills,
        isFollowing: isFollowing,
        resumeUrl: resumeUrl,
        email: userData['email'],
        mobileNumber: userData['mobile_number'],
      );
    } catch (e, stack) {
      // Return a safe fallback instead of crashing
      return PublicUser(
        id: userData['id']?.toString() ?? '',
        fullName: 'Unknown User (Error)',
        experiences: [],
        educations: [],
        skills: [],
      );
    }
  }
}

class PublicExperience {
  final String title;
  final String company;
  final bool isCurrent;
  final String? description;

  PublicExperience({
    required this.title,
    required this.company,
    required this.isCurrent,
    this.description,
  });

  factory PublicExperience.fromJson(Map<String, dynamic> json) {
    return PublicExperience(
      title: json['title'] ?? '',
      company: json['company_name'] ?? '',
      isCurrent: json['is_current'] ?? false,
      description: json['description'],
    );
  }
}

class PublicEducation {
  final String school;
  final String? degree;
  final String? description;

  PublicEducation({required this.school, this.degree, this.description});

  factory PublicEducation.fromJson(Map<String, dynamic> json) {
    return PublicEducation(
      school: json['school_name'] ?? '',
      degree: json['degree'],
      description: json['description'],
    );
  }
}
