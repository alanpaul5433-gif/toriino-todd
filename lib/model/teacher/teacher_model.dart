class TeacherModel {
  final String? userId;
  final String? name;
  final String? email;
  final String? avatarUrl;
  final String? bio;
  final List<String>? subjects;
  final String? qualification;
  final int? yearsOfExperience;
  final double? rating;
  final int? totalCourses;
  final int? totalStudents;
  final String? createdAt;

  TeacherModel({
    this.userId,
    this.name,
    this.email,
    this.avatarUrl,
    this.bio,
    this.subjects,
    this.qualification,
    this.yearsOfExperience,
    this.rating,
    this.totalCourses,
    this.totalStudents,
    this.createdAt,
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      userId: json['userId'],
      name: json['name'],
      email: json['email'],
      avatarUrl: json['avatarUrl'],
      bio: json['bio'],
      subjects: json['subjects'] != null
          ? List<String>.from(json['subjects'])
          : null,
      qualification: json['qualification'],
      yearsOfExperience: json['yearsOfExperience'],
      rating: (json['rating'] as num?)?.toDouble(),
      totalCourses: json['totalCourses'],
      totalStudents: json['totalStudents'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (bio != null) data['bio'] = bio;
    if (subjects != null) data['subjects'] = subjects;
    if (qualification != null) data['qualification'] = qualification;
    if (yearsOfExperience != null) data['yearsOfExperience'] = yearsOfExperience;
    return data;
  }
}
