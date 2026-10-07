// Subscription models. Every price, saving and status comes from the server;
// the app only displays them (see utils/money.dart) and never calculates.

double? _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

String? _toStr(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

Map<String, dynamic> _asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

/// Server-computed saving for a plan. Only present when the server found a
/// real saving — never derived in the app.
class PlanSavings {
  final double? amount;
  final double? percent;

  /// planId of the plan this saving is measured against (the monthly plan).
  final String? comparedTo;

  const PlanSavings({this.amount, this.percent, this.comparedTo});

  static PlanSavings? fromJson(dynamic json) {
    if (json is! Map) return null;
    final m = Map<String, dynamic>.from(json);
    final s = PlanSavings(
      amount: _toDouble(m['amount']),
      percent: _toDouble(m['percent']),
      comparedTo: _toStr(m['comparedTo']),
    );
    if ((s.amount ?? 0) <= 0 && (s.percent ?? 0) <= 0) return null;
    return s;
  }
}

/// One offered plan from GET /subscriptions/plans.
class SubscriptionPlan {
  final String planId;
  final String name;
  final String? audience;
  final int? months;
  final double? price;
  final String? currency;
  final PlanSavings? savings;

  const SubscriptionPlan({
    required this.planId,
    required this.name,
    this.audience,
    this.months,
    this.price,
    this.currency,
    this.savings,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    final planId = _toStr(json['planId']) ?? '';
    return SubscriptionPlan(
      planId: planId,
      name: _toStr(json['name']) ?? planId,
      audience: _toStr(json['audience']),
      months: json['months'] is num ? (json['months'] as num).toInt() : null,
      price: _toDouble(json['price']),
      currency: _toStr(json['currency']),
      savings: PlanSavings.fromJson(json['savings']),
    );
  }
}

/// GET /subscriptions/plans → { audience, plans, comingSoon }.
class SubscriptionPlansResponse {
  final String? audience;
  final List<SubscriptionPlan> plans;
  final bool comingSoon;

  const SubscriptionPlansResponse({
    this.audience,
    this.plans = const [],
    this.comingSoon = false,
  });

  factory SubscriptionPlansResponse.fromJson(dynamic json) {
    final m = _asMap(json);
    final plans = (m['plans'] is List ? m['plans'] as List : const [])
        .whereType<Map>()
        .map((p) => SubscriptionPlan.fromJson(Map<String, dynamic>.from(p)))
        .where((p) => p.planId.isNotEmpty)
        .toList();
    return SubscriptionPlansResponse(
      audience: _toStr(m['audience']),
      plans: plans,
      // No offered plans means nothing can be bought, whatever the flag says.
      comingSoon: m['comingSoon'] == true || plans.isEmpty,
    );
  }

  SubscriptionPlan? planById(String? planId) {
    if (planId == null) return null;
    for (final p in plans) {
      if (p.planId == planId) return p;
    }
    return null;
  }
}

/// GET /subscriptions/me — the only source of truth for premium in the app.
class SubscriptionStatus {
  final bool premium;

  /// none | incomplete | active | trialing | past_due | canceled | …
  final String status;
  final String? planId;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;

  const SubscriptionStatus({
    required this.premium,
    required this.status,
    this.planId,
    this.currentPeriodEnd,
    this.cancelAtPeriodEnd = false,
  });

  factory SubscriptionStatus.fromJson(dynamic json) {
    final m = _asMap(json);
    return SubscriptionStatus(
      premium: m['premium'] == true,
      status: _toStr(m['status']) ?? 'none',
      planId: _toStr(m['planId']),
      currentPeriodEnd: _parseDate(m['currentPeriodEnd']),
      cancelAtPeriodEnd: m['cancelAtPeriodEnd'] == true,
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v is String) return DateTime.tryParse(v)?.toLocal();
    if (v is num) {
      // Epoch seconds (Stripe style) or milliseconds.
      final ms = v < 1e12 ? (v * 1000).toInt() : v.toInt();
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return null;
  }

  bool get hasSubscription => status != 'none' && status.isNotEmpty;

  /// Whether the server would accept a cancellation request.
  bool get canCancel =>
      premium &&
      !cancelAtPeriodEnd &&
      (status == 'active' || status == 'trialing' || status == 'past_due');

  String get statusLabel {
    switch (status) {
      case 'none':
        return 'No active plan';
      case 'active':
        return cancelAtPeriodEnd ? 'Active — cancels at period end' : 'Active';
      case 'trialing':
        return 'Trial';
      case 'incomplete':
        return 'Payment incomplete';
      case 'incomplete_expired':
        return 'Payment expired';
      case 'past_due':
        return 'Payment past due';
      case 'unpaid':
        return 'Unpaid';
      case 'canceled':
        return 'Canceled';
      default:
        return status.replaceAll('_', ' ');
    }
  }
}

/// POST /subscriptions → { subscriptionId, clientSecret, status, message }.
class SubscriptionCheckout {
  final String? subscriptionId;
  final String? clientSecret;
  final String? status;
  final String? message;

  const SubscriptionCheckout({
    this.subscriptionId,
    this.clientSecret,
    this.status,
    this.message,
  });

  factory SubscriptionCheckout.fromJson(dynamic json) {
    final m = _asMap(json);
    return SubscriptionCheckout(
      subscriptionId: _toStr(m['subscriptionId']),
      clientSecret: _toStr(m['clientSecret']),
      status: _toStr(m['status']),
      message: _toStr(m['message']),
    );
  }
}
