class MentorModel {
  final String? userId;
  final String? name;
  final String? email;
  final String? avatarUrl;
  final String? bio;
  final List<String>? expertise;
  final double? hourlyRate;
  final double? rating;
  final int? totalSessions;
  final int? totalStudents;
  final String? introVideoUrl;
  final String? createdAt;

  MentorModel({
    this.userId,
    this.name,
    this.email,
    this.avatarUrl,
    this.bio,
    this.expertise,
    this.hourlyRate,
    this.rating,
    this.totalSessions,
    this.totalStudents,
    this.introVideoUrl,
    this.createdAt,
  });

  factory MentorModel.fromJson(Map<String, dynamic> json) {
    return MentorModel(
      userId: json['userId'],
      name: json['name'],
      email: json['email'],
      avatarUrl: json['avatarUrl'],
      bio: json['bio'],
      expertise: json['expertise'] != null
          ? List<String>.from(json['expertise'])
          : null,
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      totalSessions: json['totalSessions'],
      totalStudents: json['totalStudents'],
      introVideoUrl: json['introVideoUrl'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (bio != null) data['bio'] = bio;
    if (expertise != null) data['expertise'] = expertise;
    if (hourlyRate != null) data['hourlyRate'] = hourlyRate;
    if (introVideoUrl != null) data['introVideoUrl'] = introVideoUrl;
    return data;
  }
}

class MentorListResponse {
  final List<MentorModel> mentors;
  final int count;

  MentorListResponse({required this.mentors, required this.count});

  factory MentorListResponse.fromJson(Map<String, dynamic> json) {
    return MentorListResponse(
      mentors: (json['mentors'] as List)
          .map((e) => MentorModel.fromJson(e))
          .toList(),
      count: json['count'] ?? 0,
    );
  }
}
