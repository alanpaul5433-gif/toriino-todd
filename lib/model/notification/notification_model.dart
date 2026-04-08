class NotificationModel {
  final String? userId;
  final String? sortKey;
  final String? title;
  final String? message;
  final String? type;
  final Map<String, dynamic>? data;
  final bool? isRead;
  final String? createdAt;

  NotificationModel({
    this.userId,
    this.sortKey,
    this.title,
    this.message,
    this.type,
    this.data,
    this.isRead,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      userId: json['userId'],
      sortKey: json['sortKey'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : null,
      isRead: json['isRead'],
      createdAt: json['createdAt'],
    );
  }
}

class NotificationListResponse {
  final List<NotificationModel> notifications;
  final int count;

  NotificationListResponse({
    required this.notifications,
    required this.count,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    return NotificationListResponse(
      notifications: (json['notifications'] as List)
          .map((e) => NotificationModel.fromJson(e))
          .toList(),
      count: json['count'] ?? 0,
    );
  }
}
