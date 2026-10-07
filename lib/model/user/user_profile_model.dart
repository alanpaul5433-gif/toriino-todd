class UserProfileModel {
  final String? userId;
  final String? name;
  final String? email;
  final String? phone;
  final String? role;
  final String? bio;
  final String? avatarUrl;
  final String? dateOfBirth;
  final String? location;
  final List<String>? interests;
  final double? rating;
  final String? createdAt;
  final String? updatedAt;
  final String? experience;
  final String? language;
  final double? hourlyRate;
  final String? educationLevel;
  final String? title;
  final String? industry;
  final List<String>? expertise;
  final List<String>? skills;

  UserProfileModel({
    this.userId,
    this.name,
    this.email,
    this.phone,
    this.role,
    this.bio,
    this.avatarUrl,
    this.dateOfBirth,
    this.location,
    this.interests,
    this.rating,
    this.createdAt,
    this.updatedAt,
    this.experience,
    this.language,
    this.hourlyRate,
    this.educationLevel,
    this.title,
    this.industry,
    this.expertise,
    this.skills,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['userId'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'],
      bio: json['bio'],
      avatarUrl: json['avatarUrl'],
      dateOfBirth: json['dateOfBirth'],
      location: json['location'],
      interests: json['interests'] != null
          ? List<String>.from(json['interests'])
          : null,
      rating: (json['rating'] as num?)?.toDouble(),
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      experience: json['experience'],
      language: json['language'],
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
      educationLevel: json['educationLevel'],
      title: json['title'],
      industry: json['industry'],
      expertise: _stringList(json['expertise']),
      skills: _stringList(json['skills']),
    );
  }

  /// Accepts either a JSON array or a comma-separated string.
  static List<String>? _stringList(dynamic v) {
    if (v == null) return null;
    if (v is List) return v.map((e) => e.toString()).toList();
    if (v is String) {
      return v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (userId != null) data['userId'] = userId;
    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;
    if (role != null) data['role'] = role;
    if (bio != null) data['bio'] = bio;
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
    if (dateOfBirth != null) data['dateOfBirth'] = dateOfBirth;
    if (location != null) data['location'] = location;
    if (interests != null) data['interests'] = interests;
    if (createdAt != null) data['createdAt'] = createdAt;
    if (updatedAt != null) data['updatedAt'] = updatedAt;
    if (experience != null) data['experience'] = experience;
    if (language != null) data['language'] = language;
    if (hourlyRate != null) data['hourlyRate'] = hourlyRate;
    if (educationLevel != null) data['educationLevel'] = educationLevel;
    if (title != null) data['title'] = title;
    if (industry != null) data['industry'] = industry;
    if (expertise != null) data['expertise'] = expertise;
    if (skills != null) data['skills'] = skills;
    return data;
  }
}
