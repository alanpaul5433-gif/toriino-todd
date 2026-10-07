import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:toriino_todd/config/app_config.dart';
import 'package:toriino_todd/data/appURL/app_url.dart';
import 'package:toriino_todd/data/app_exception.dart';
import 'package:toriino_todd/model/payment/pricing_model.dart';
import 'package:toriino_todd/repository/payments_repo.dart';
import 'package:toriino_todd/services/auth_service.dart';
import 'package:toriino_todd/utils/utils.dart';

class StripeService {
  // ── Init (call once in main.dart before runApp) ──────
  static void init() {
    Stripe.publishableKey = AppConfig.stripePublishableKey;
    Stripe.merchantIdentifier = 'merchant.com.torino.app';
  }

  // ── Subscription checkout ────────────────────────────
  // Presents the PaymentSheet for a clientSecret returned by
  // POST /subscriptions. Success means only that the sheet completed — the
  // plan is activated by the Stripe webhook; callers must poll
  // GET /subscriptions/me and never mark anything active locally.
  //
  // Returns {success, message} and, when the user dismissed the sheet,
  // {cancelled: true}.
  static Future<Map<String, dynamic>> presentSubscriptionSheet(
      String clientSecret) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Torino',
          style: ThemeMode.dark,
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      return {'success': true, 'message': 'Payment received'};
    } on StripeException catch (e) {
      final cancelled = e.error.code == FailureCode.Canceled;
      return {
        'success': false,
        'cancelled': cancelled,
        'message': cancelled
            ? 'Payment cancelled'
            : (e.error.localizedMessage ?? 'Payment failed'),
      };
    } catch (e) {
      return {'success': false, 'message': Utils.errorMessage(e)};
    }
  }

  // ── Course purchase ──────────────────────────────────
  // Price and teacherId are resolved server-side from DynamoDB.
  // The client only supplies courseId (and a display title for the description).
  //
  // Success here means only that the PaymentSheet completed. The student is
  // enrolled by the Stripe webhook afterwards — callers must NOT call
  // POST /courses/{id}/enroll; poll GET /courses/my-courses instead
  // (see CourseEnrollmentService).
  //
  // Returns {success, message} and, when the user dismissed the sheet,
  // {cancelled: true}.
  static Future<Map<String, dynamic>> purchaseCourse({
    required String courseId,
    required String courseTitle,
  }) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse('${AppUrl.baseUrl}/payments/create-intent'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'type': 'course_purchase',
          'courseId': courseId,
          'description': 'Course: $courseTitle',
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        // e.g. 503 {"error": "Stripe not configured"} — show the server's text.
        return {
          'success': false,
          'message': _serverError(response.body) ??
              'Payment setup failed (${response.statusCode})',
        };
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final clientSecret = data['clientSecret'] as String?;
      if (clientSecret == null) {
        return {'success': false, 'message': 'Payment setup error: missing client secret'};
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Torino',
          style: ThemeMode.dark,
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      return {'success': true, 'message': 'Payment received'};
    } on StripeException catch (e) {
      final cancelled = e.error.code == FailureCode.Canceled;
      return {
        'success': false,
        'cancelled': cancelled,
        'message': cancelled
            ? 'Payment cancelled'
            : (e.error.localizedMessage ?? 'Payment failed'),
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static String? _serverError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final msg = decoded['error'] ?? decoded['message'];
        if (msg is String && msg.trim().isNotEmpty) return msg;
      }
    } catch (_) {}
    return null;
  }

  // ── Session booking payment ──────────────────────────
  // The server owns the price. The client sends only the booked sessionId;
  // POST /payments/create-intent { type: session_booking, sessionId,
  // useWallet: true } either:
  //  * pays the FULL price from the wallet (paidWithWallet: true) — the session
  //    is already confirmed; no Stripe sheet, or
  //  * returns a clientSecret for the FULL price — the PaymentSheet is shown
  //    and the Stripe webhook confirms the session.
  // The app never calls /wallet/deduct and never sends an amount.
  static Future<SessionPaymentResult> payForSession({
    required String sessionId,
    PaymentsRepo? repo,
  }) async {
    final SessionPaymentIntent intent;
    try {
      intent = await (repo ?? PaymentsRepo()).createSessionIntent(sessionId);
    } on ConflictException catch (e) {
      // 409 — the session is already paid.
      return SessionPaymentResult(
          SessionPaymentOutcome.alreadyPaid, Utils.errorMessage(e));
    } catch (e) {
      // e.g. 503 "Stripe not configured" / "Platform fee not configured".
      return SessionPaymentResult.failed(Utils.errorMessage(e));
    }

    if (intent.paidWithWallet) {
      return SessionPaymentResult(
        SessionPaymentOutcome.paidWithWallet,
        'Paid from your wallet',
        amountCharged: intent.amountCharged,
        walletBalance: intent.walletBalance,
      );
    }

    final clientSecret = intent.clientSecret;
    if (clientSecret == null) {
      return SessionPaymentResult.failed(
          'Payment setup error: missing client secret');
    }

    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Torino',
          style: ThemeMode.dark,
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      return SessionPaymentResult(
        SessionPaymentOutcome.paidByCard,
        'Payment received',
        amountCharged: intent.amountDue,
      );
    } on StripeException catch (e) {
      final cancelled = e.error.code == FailureCode.Canceled;
      return SessionPaymentResult(
        cancelled
            ? SessionPaymentOutcome.cancelled
            : SessionPaymentOutcome.failed,
        cancelled
            ? 'Payment cancelled'
            : (e.error.localizedMessage ?? 'Payment failed'),
      );
    } catch (e) {
      return SessionPaymentResult.failed(Utils.errorMessage(e));
    }
  }
}

enum SessionPaymentOutcome {
  paidWithWallet,
  paidByCard,

  /// 409 from the server: this session was already paid.
  alreadyPaid,
  cancelled,
  failed,
}

/// Outcome of [StripeService.payForSession]. Amounts are the server's values.
class SessionPaymentResult {
  final SessionPaymentOutcome outcome;
  final String message;
  final double? amountCharged;
  final double? walletBalance;

  const SessionPaymentResult(
    this.outcome,
    this.message, {
    this.amountCharged,
    this.walletBalance,
  });

  const SessionPaymentResult.failed(this.message)
      : outcome = SessionPaymentOutcome.failed,
        amountCharged = null,
        walletBalance = null;

  bool get isPaid =>
      outcome == SessionPaymentOutcome.paidWithWallet ||
      outcome == SessionPaymentOutcome.paidByCard;
}
