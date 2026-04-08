class EarningsModel {
  final String? userId;
  final String? periodKey;
  final double? amount;
  final int? sessions;
  final String? createdAt;

  EarningsModel({
    this.userId,
    this.periodKey,
    this.amount,
    this.sessions,
    this.createdAt,
  });

  factory EarningsModel.fromJson(Map<String, dynamic> json) {
    return EarningsModel(
      userId: json['userId'],
      periodKey: json['periodKey'],
      amount: (json['amount'] as num?)?.toDouble(),
      sessions: json['sessions'],
      createdAt: json['createdAt'],
    );
  }
}

class EarningsSummaryResponse {
  final EarningsModel currentMonth;
  final double totalEarnings;
  final List<EarningsModel> monthlyBreakdown;

  EarningsSummaryResponse({
    required this.currentMonth,
    required this.totalEarnings,
    required this.monthlyBreakdown,
  });

  factory EarningsSummaryResponse.fromJson(Map<String, dynamic> json) {
    return EarningsSummaryResponse(
      currentMonth: EarningsModel.fromJson(json['currentMonth']),
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0,
      monthlyBreakdown: (json['monthlyBreakdown'] as List)
          .map((e) => EarningsModel.fromJson(e))
          .toList(),
    );
  }
}
