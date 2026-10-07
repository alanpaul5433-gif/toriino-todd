class CourseModel {
  final String? courseId;
  final String? teacherId;
  final String? title;
  final String? description;
  final String? category;
  final String? duration;
  final double? price;
  final String? imageUrl;
  final String? level;
  final String? language;
  final double? rating;
  final int? enrollmentCount;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  /// Display name of the teacher, when the API includes one.
  final String? teacherName;

  /// Only on GET /courses/my-courses: the caller's own enrollment status
  /// (`course.enrollment.status`, e.g. 'active' or 'completed').
  final String? enrollmentStatus;

  /// Only on GET /courses/my-courses: `course.enrollment.progress` (0-100).
  final int? enrollmentProgress;

  CourseModel({
    this.courseId,
    this.teacherId,
    this.title,
    this.description,
    this.category,
    this.duration,
    this.price,
    this.imageUrl,
    this.level,
    this.language,
    this.rating,
    this.enrollmentCount,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.teacherName,
    this.enrollmentStatus,
    this.enrollmentProgress,
  });

  bool get isCompleted => enrollmentStatus == 'completed';

  CourseModel copyWith({String? enrollmentStatus}) {
    return CourseModel(
      courseId: courseId,
      teacherId: teacherId,
      title: title,
      description: description,
      category: category,
      duration: duration,
      price: price,
      imageUrl: imageUrl,
      level: level,
      language: language,
      rating: rating,
      enrollmentCount: enrollmentCount,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      teacherName: teacherName,
      enrollmentStatus: enrollmentStatus ?? this.enrollmentStatus,
      enrollmentProgress: enrollmentProgress,
    );
  }

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    final enrollment = json['enrollment'];
    final teacherName = json['teacherName'] ?? json['instructorName'];
    return CourseModel(
      courseId: json['courseId'],
      teacherId: json['teacherId'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      duration: json['duration']?.toString(),
      price: (json['price'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'],
      level: json['level'],
      language: json['language'],
      rating: (json['rating'] as num?)?.toDouble(),
      enrollmentCount: json['enrollmentCount'],
      status: json['status'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      teacherName: teacherName is String && teacherName.isNotEmpty
          ? teacherName
          : null,
      enrollmentStatus:
          enrollment is Map && enrollment['status'] is String
              ? enrollment['status'] as String
              : null,
      enrollmentProgress:
          enrollment is Map && enrollment['progress'] is num
              ? (enrollment['progress'] as num).round()
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (courseId != null) data['courseId'] = courseId;
    if (teacherId != null) data['teacherId'] = teacherId;
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (category != null) data['category'] = category;
    if (duration != null) data['duration'] = duration;
    if (price != null) data['price'] = price;
    if (imageUrl != null) data['imageUrl'] = imageUrl;
    if (level != null) data['level'] = level;
    if (language != null) data['language'] = language;
    if (rating != null) data['rating'] = rating;
    if (enrollmentCount != null) data['enrollmentCount'] = enrollmentCount;
    if (status != null) data['status'] = status;
    return data;
  }
}

class CourseListResponse {
  final List<CourseModel> courses;
  final int count;

  CourseListResponse({required this.courses, required this.count});

  factory CourseListResponse.fromJson(Map<String, dynamic> json) {
    return CourseListResponse(
      courses: (json['courses'] as List? ?? [])
          .map((e) => CourseModel.fromJson(e))
          .toList(),
      count: json['count'] ?? 0,
    );
  }
}
