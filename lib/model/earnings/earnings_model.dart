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

  /// Server-computed balance that can be withdrawn. Null when the server did
  /// not send it — never derived on the client.
  final double? availableBalance;

  /// Server-reported earnings not yet settled.
  final double? pendingEarnings;

  /// Server-reported withdrawals still in progress.
  final double? pendingWithdrawals;

  EarningsSummaryResponse({
    required this.currentMonth,
    required this.totalEarnings,
    required this.totalWithdrawn,
    required this.monthlyBreakdown,
    this.availableBalance,
    this.pendingEarnings,
    this.pendingWithdrawals,
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
      availableBalance: (json['availableBalance'] as num?)?.toDouble(),
      pendingEarnings: (json['pendingEarnings'] as num?)?.toDouble(),
      pendingWithdrawals: (json['pendingWithdrawals'] as num?)?.toDouble(),
    );
  }
}
