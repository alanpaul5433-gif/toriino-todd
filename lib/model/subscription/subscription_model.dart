class SubscriptionModel {
  final String? userId;
  final String? subscriptionId;
  final String? planName;
  final String? planType;
  final double? price;
  final String? status;
  final String? startDate;
  final String? endDate;
  final String? createdAt;

  SubscriptionModel({
    this.userId,
    this.subscriptionId,
    this.planName,
    this.planType,
    this.price,
    this.status,
    this.startDate,
    this.endDate,
    this.createdAt,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      userId: json['userId'],
      subscriptionId: json['subscriptionId'],
      planName: json['planName'],
      planType: json['planType'],
      price: (json['price'] as num?)?.toDouble(),
      status: json['status'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      createdAt: json['createdAt'],
    );
  }
}
