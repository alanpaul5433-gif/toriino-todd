/// Response of GET /users/{id}.
///
/// For a teacher/mentor this is their public profile plus published courses.
/// For a student it only contains what the caller shares with them
/// ([sharedCourses], [sharedSessions]).
class PublicUserModel {
  final String? userId;

  /// "Teacher", "Mentor" or "Student".
  final String? role;
  final String? name;
  final String? avatarUrl;
  final String? bio;

  // Teacher / mentor only
  final String? title;
  final List<String> expertise;
  final List<String> specialties;
  final String? language;
  final String? introVideoUrl;
  final double? rating;
  final int? reviewCount;
  final double? hourlyRate;
  final int? totalSessions;
  final List<PublicCourseModel> courses;

  // Student only
  final List<SharedCourseModel> sharedCourses;
  final List<SharedSessionModel> sharedSessions;

  PublicUserModel({
    this.userId,
    this.role,
    this.name,
    this.avatarUrl,
    this.bio,
    this.title,
    this.expertise = const [],
    this.specialties = const [],
    this.language,
    this.introVideoUrl,
    this.rating,
    this.reviewCount,
    this.hourlyRate,
    this.totalSessions,
    this.courses = const [],
    this.sharedCourses = const [],
    this.sharedSessions = const [],
  });

  bool get isStudent => (role ?? '').toLowerCase() == 'student';

  factory PublicUserModel.fromJson(Map<String, dynamic> json) {
    return PublicUserModel(
      userId: _str(json['userId']),
      role: _str(json['role']),
      name: _str(json['name']),
      avatarUrl: _str(json['avatarUrl']),
      bio: _str(json['bio']),
      title: _str(json['title']),
      expertise: _strList(json['expertise']),
      specialties: _strList(json['specialties']),
      language: _str(json['language']),
      introVideoUrl: _str(json['introVideoUrl']),
      rating: _num(json['rating']),
      reviewCount: _int(json['reviewCount']),
      hourlyRate: _num(json['hourlyRate']),
      totalSessions: _int(json['totalSessions']),
      courses: _list(json['courses'], PublicCourseModel.fromJson),
      sharedCourses: _list(json['sharedCourses'], SharedCourseModel.fromJson),
      sharedSessions: _list(
        json['sharedSessions'],
        SharedSessionModel.fromJson,
      ),
    );
  }
}

/// A published course on a teacher/mentor public profile.
class PublicCourseModel {
  final String? courseId;
  final String? title;
  final double? price;
  final String? thumbnail;
  final double? rating;
  final String? category;
  final String? level;
  final String? duration;

  PublicCourseModel({
    this.courseId,
    this.title,
    this.price,
    this.thumbnail,
    this.rating,
    this.category,
    this.level,
    this.duration,
  });

  factory PublicCourseModel.fromJson(Map<String, dynamic> json) {
    return PublicCourseModel(
      courseId: _str(json['courseId']),
      title: _str(json['title']),
      price: _num(json['price']),
      thumbnail: _str(json['thumbnail']),
      rating: _num(json['rating']),
      category: _str(json['category']),
      level: _str(json['level']),
      duration: _str(json['duration']),
    );
  }
}

/// A course the viewing teacher/mentor teaches and the student is enrolled in.
class SharedCourseModel {
  final String? courseId;
  final String? title;
  final String? thumbnail;
  final String? enrollmentStatus;
  final int? progress;
  final String? enrolledAt;

  SharedCourseModel({
    this.courseId,
    this.title,
    this.thumbnail,
    this.enrollmentStatus,
    this.progress,
    this.enrolledAt,
  });

  factory SharedCourseModel.fromJson(Map<String, dynamic> json) {
    return SharedCourseModel(
      courseId: _str(json['courseId']),
      title: _str(json['title']),
      thumbnail: _str(json['thumbnail']),
      enrollmentStatus: _str(json['enrollmentStatus']),
      progress: _int(json['progress']),
      enrolledAt: _str(json['enrolledAt']),
    );
  }
}

/// A session between the viewing teacher/mentor and the student.
class SharedSessionModel {
  final String? sessionId;
  final String? title;
  final String? topic;
  final String? dateTime;
  final String? duration;
  final String? status;
  final String? sessionType;

  SharedSessionModel({
    this.sessionId,
    this.title,
    this.topic,
    this.dateTime,
    this.duration,
    this.status,
    this.sessionType,
  });

  factory SharedSessionModel.fromJson(Map<String, dynamic> json) {
    return SharedSessionModel(
      sessionId: _str(json['sessionId']),
      title: _str(json['title']),
      topic: _str(json['topic']),
      dateTime: _str(json['dateTime']),
      duration: _str(json['duration']),
      status: _str(json['status']),
      sessionType: _str(json['sessionType']),
    );
  }
}

String? _str(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

double? _num(dynamic v) => v is num ? v.toDouble() : null;

int? _int(dynamic v) => v is num ? v.round() : null;

List<String> _strList(dynamic v) =>
    v is List
        ? v
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toList()
        : const [];

List<T> _list<T>(dynamic v, T Function(Map<String, dynamic>) parse) =>
    v is List
        ? v
            .whereType<Map>()
            .map((e) => parse(Map<String, dynamic>.from(e)))
            .toList()
        : const [];
