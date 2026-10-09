/// Server-computed pricing breakdown (the app never calculates money).
///
/// Sent by the API as `pricing` on course and session objects:
/// `{ currency, price, platformFeePercent, platformFee, teacherShare }`.
/// `pricing` is absent when the server has no configured platform fee — then
/// only the plain `price` is shown.
class PricingModel {
  final String? currency;
  final double? price;
  final double? platformFeePercent;
  final double? platformFee;
  final double? teacherShare;

  const PricingModel({
    this.currency,
    this.price,
    this.platformFeePercent,
    this.platformFee,
    this.teacherShare,
  });

  static double? _num(dynamic v) => v is num ? v.toDouble() : null;

  /// Returns null unless [json] is a map (so an absent `pricing` stays null).
  static PricingModel? tryParse(dynamic json) {
    if (json is! Map) return null;
    return PricingModel(
      currency: json['currency'] is String ? json['currency'] as String : null,
      price: _num(json['price']),
      platformFeePercent: _num(json['platformFeePercent']),
      platformFee: _num(json['platformFee']),
      teacherShare: _num(json['teacherShare']),
    );
  }
}

/// GET /payments/quote — a server quote, displayed as-is.
///
/// Course quotes have `walletApplied: 0`; mentor/session quotes add
/// `walletBalance`. The wallet is all-or-nothing on the server:
/// `walletApplied` is either the full price or 0.
class PaymentQuoteModel {
  final String? currency;
  final double? price;
  final double? platformFeePercent;
  final double? platformFee;
  final double? teacherShare;
  final double? walletBalance;
  final double? walletApplied;
  final double? amountDue;

  const PaymentQuoteModel({
    this.currency,
    this.price,
    this.platformFeePercent,
    this.platformFee,
    this.teacherShare,
    this.walletBalance,
    this.walletApplied,
    this.amountDue,
  });

  static double? _num(dynamic v) => v is num ? v.toDouble() : null;

  factory PaymentQuoteModel.fromJson(Map<String, dynamic> json) {
    return PaymentQuoteModel(
      currency: json['currency'] is String ? json['currency'] as String : null,
      price: _num(json['price']),
      platformFeePercent: _num(json['platformFeePercent']),
      platformFee: _num(json['platformFee']),
      teacherShare: _num(json['teacherShare']),
      walletBalance: _num(json['walletBalance']),
      walletApplied: _num(json['walletApplied']),
      amountDue: _num(json['amountDue']),
    );
  }

  /// True when the server says the wallet pays the whole price.
  bool get paidFromWallet => (walletApplied ?? 0) > 0;
}

/// Result of POST /payments/create-intent for a session booking.
class SessionPaymentIntent {
  /// The wallet covered the full price; the session is already confirmed and
  /// paid — no Stripe sheet.
  final bool paidWithWallet;
  final String? sessionId;
  final double? amountCharged;
  final double? walletBalance;

  /// Present when the card must be charged (full price) via the PaymentSheet.
  final String? clientSecret;
  final String? paymentIntentId;
  final double? amountDue;

  const SessionPaymentIntent({
    this.paidWithWallet = false,
    this.sessionId,
    this.amountCharged,
    this.walletBalance,
    this.clientSecret,
    this.paymentIntentId,
    this.amountDue,
  });

  static double? _num(dynamic v) => v is num ? v.toDouble() : null;

  factory SessionPaymentIntent.fromJson(Map<String, dynamic> json) {
    final secret = json['clientSecret'];
    return SessionPaymentIntent(
      paidWithWallet: json['paidWithWallet'] == true,
      sessionId: json['sessionId'] is String ? json['sessionId'] as String : null,
      amountCharged: _num(json['amountCharged']),
      walletBalance: _num(json['walletBalance']),
      clientSecret: secret is String && secret.isNotEmpty ? secret : null,
      paymentIntentId: json['paymentIntentId'] is String
          ? json['paymentIntentId'] as String
          : null,
      amountDue: _num(json['amountDue']),
    );
  }
}
