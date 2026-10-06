class EarningsModel {
  final String? userId;
  final String? periodKey;
  final double? amount;
  final int? sessions;
  final String? createdAt;
  final String? type;

  EarningsModel({
    this.userId,
    this.periodKey,
    this.amount,
    this.sessions,
    this.createdAt,
    this.type,
  });

  factory EarningsModel.fromJson(Map<String, dynamic> json) {
    return EarningsModel(
      userId: json['userId'],
      periodKey: json['periodKey'],
      amount: (json['amount'] as num?)?.toDouble(),
      sessions: json['sessions'],
      createdAt: json['createdAt'],
      type: json['type'],
    );
  }
}

class EarningsSummaryResponse {
  final EarningsModel currentMonth;
  final double totalEarnings;
  final double totalWithdrawn;
  final List<EarningsModel> monthlyBreakdown;

  EarningsSummaryResponse({
    required this.currentMonth,
    required this.totalEarnings,
    required this.totalWithdrawn,
    required this.monthlyBreakdown,
  });

  factory EarningsSummaryResponse.fromJson(Map<String, dynamic> json) {
    return EarningsSummaryResponse(
      currentMonth: EarningsModel.fromJson(
          json['currentMonth'] as Map<String, dynamic>? ?? {}),
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0,
      totalWithdrawn: (json['totalWithdrawn'] as num?)?.toDouble() ?? 0,
      monthlyBreakdown: (json['monthlyBreakdown'] as List? ?? [])
          .map((e) => EarningsModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
