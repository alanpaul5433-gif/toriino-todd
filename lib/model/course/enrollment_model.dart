class EnrollmentModel {
  final String? studentId;
  final String? courseId;
  final String? enrolledAt;
  final int? progress;
  final String? status;

  EnrollmentModel({
    this.studentId,
    this.courseId,
    this.enrolledAt,
    this.progress,
    this.status,
  });

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    return EnrollmentModel(
      studentId: json['studentId'],
      courseId: json['courseId'],
      enrolledAt: json['enrolledAt'],
      progress: json['progress'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'courseId': courseId,
      'enrolledAt': enrolledAt,
      'progress': progress,
      'status': status,
    };
  }
}
