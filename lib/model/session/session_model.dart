class SessionModel {
  final String? sessionId;
  final String? studentId;
  final String? mentorId;
  final String? dateTime;
  final int? duration;
  final String? topic;
  final String? notes;
  final String? status;
  final String? meetingLink;
  final String? createdAt;
  final String? updatedAt;
  // Group session fields
  final String? sessionType;
  final int? maxParticipants;
  final double? price;
  final String? description;

  SessionModel({
    this.sessionId,
    this.studentId,
    this.mentorId,
    this.dateTime,
    this.duration,
    this.topic,
    this.notes,
    this.status,
    this.meetingLink,
    this.createdAt,
    this.updatedAt,
    this.sessionType,
    this.maxParticipants,
    this.price,
    this.description,
  });

  bool get isGroup => sessionType == 'group';

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      sessionId: json['sessionId'],
      studentId: json['studentId'],
      mentorId: json['mentorId'],
      dateTime: json['dateTime'],
      duration: json['duration'],
      topic: json['topic'],
      notes: json['notes'],
      status: json['status'],
      meetingLink: json['meetingLink'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      sessionType: json['sessionType'],
      maxParticipants: json['maxParticipants'],
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (mentorId != null) data['mentorId'] = mentorId;
    if (dateTime != null) data['dateTime'] = dateTime;
    if (duration != null) data['duration'] = duration;
    if (topic != null) data['topic'] = topic;
    if (notes != null) data['notes'] = notes;
    if (status != null) data['status'] = status;
    if (sessionType != null) data['sessionType'] = sessionType;
    if (maxParticipants != null) data['maxParticipants'] = maxParticipants;
    if (price != null) data['price'] = price;
    if (description != null) data['description'] = description;
    return data;
  }
}

class SessionListResponse {
  final List<SessionModel> sessions;
  final int count;

  SessionListResponse({required this.sessions, required this.count});

  factory SessionListResponse.fromJson(Map<String, dynamic> json) {
    return SessionListResponse(
      sessions: (json['sessions'] as List? ?? [])
          .map((e) => SessionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: json['count'] ?? 0,
    );
  }
}
