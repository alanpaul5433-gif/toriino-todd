class LessonModel {
  final String? courseId;
  final String? lessonId;
  final String? title;
  final String? description;
  final String? videoUrl;
  final String? duration;
  final int? order;
  final String? createdAt;

  LessonModel({
    this.courseId,
    this.lessonId,
    this.title,
    this.description,
    this.videoUrl,
    this.duration,
    this.order,
    this.createdAt,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      courseId: json['courseId'],
      lessonId: json['lessonId'],
      title: json['title'],
      description: json['description'],
      videoUrl: json['videoUrl'],
      duration: json['duration'],
      order: json['order'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (videoUrl != null) data['videoUrl'] = videoUrl;
    if (duration != null) data['duration'] = duration;
    if (order != null) data['order'] = order;
    return data;
  }
}
