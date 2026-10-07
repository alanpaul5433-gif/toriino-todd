class LessonModel {
  final String? courseId;
  final String? lessonId;
  final String? title;
  final String? description;

  /// S3 key of the (private) lesson video, folder `lessons/`. Play it through
  /// GET /courses/{courseId}/lessons/{lessonId}/media — never build a URL.
  final String? videoKey;

  /// S3 key of the optional lesson material, folder `course-materials/`.
  final String? materialKey;

  /// Legacy lessons only: a directly playable URL stored before media became
  /// private. Used only when [videoKey] is absent.
  final String? videoUrl;

  /// Legacy lessons only: a direct material URL. Used only when [materialKey]
  /// is absent.
  final String? materialUrl;

  /// Link-type lessons only: an external https page (not private media).
  final String? url;

  final String? materialType;
  final String? duration;
  final int? order;
  final String? createdAt;

  LessonModel({
    this.courseId,
    this.lessonId,
    this.title,
    this.description,
    this.videoKey,
    this.materialKey,
    this.videoUrl,
    this.materialUrl,
    this.url,
    this.materialType,
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
      videoKey: json['videoKey'],
      materialKey: json['materialKey'],
      videoUrl: json['videoUrl'],
      materialUrl: json['materialUrl'],
      url: json['url'] is String ? json['url'] as String : null,
      materialType: json['materialType'],
      duration: json['duration']?.toString(),
      order: json['order'] is num
          ? (json['order'] as num).toInt()
          : int.tryParse('${json['order']}'),
      createdAt: json['createdAt'],
    );
  }

  bool get hasVideoKey => (videoKey ?? '').isNotEmpty;
  bool get hasMaterialKey => (materialKey ?? '').isNotEmpty;

  /// True when the lesson has a video to play (private key or legacy URL).
  bool get hasVideo => hasVideoKey || (videoUrl ?? '').isNotEmpty;

  /// True when the lesson has a material to open (private key or legacy URL).
  bool get hasMaterial => hasMaterialKey || (materialUrl ?? '').isNotEmpty;

  /// True for a link-type lesson that points at an external page.
  bool get hasLink => (url ?? '').isNotEmpty;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (videoKey != null) data['videoKey'] = videoKey;
    if (materialKey != null) data['materialKey'] = materialKey;
    if (url != null) data['url'] = url;
    if (materialType != null) data['materialType'] = materialType;
    if (duration != null) data['duration'] = duration;
    if (order != null) data['order'] = order;
    return data;
  }
}

/// Response of GET /courses/{courseId}/lessons/{lessonId}/media.
/// The URLs are pre-signed and expire after [expiresIn] seconds; fetch a new
/// one right before every play/open instead of storing them.
class LessonMediaModel {
  final String? videoUrl;
  final String? materialUrl;
  final int expiresIn;

  LessonMediaModel({this.videoUrl, this.materialUrl, this.expiresIn = 300});

  factory LessonMediaModel.fromJson(Map<String, dynamic> json) {
    final v = json['videoUrl'];
    final m = json['materialUrl'];
    return LessonMediaModel(
      videoUrl: v is String && v.isNotEmpty ? v : null,
      materialUrl: m is String && m.isNotEmpty ? m : null,
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 300,
    );
  }
}
