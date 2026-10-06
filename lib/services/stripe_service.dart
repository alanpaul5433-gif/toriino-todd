import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:toriino_todd/config/app_config.dart';
import 'package:toriino_todd/data/appURL/app_url.dart';
import 'package:toriino_todd/services/auth_service.dart';

class StripeService {
  // ── Init (call once in main.dart before runApp) ──────
  static void init() {
    Stripe.publishableKey = AppConfig.stripePublishableKey;
    Stripe.merchantIdentifier = 'merchant.com.torino.app';
  }

  // ── Create payment intent via Lambda ─────────────────
  // Lambda calls Stripe with the secret key and returns a clientSecret.
  static Future<Map<String, dynamic>> _createPaymentIntent({
    required int amountInCents,
    required String currency,
    required String description,
    Map<String, String>? metadata,
  }) async {
    try {
      final token = await AuthService.getToken();
      final body = <String, dynamic>{
        'amount': amountInCents,
        'currency': currency,
        'description': description,
        if (metadata != null) 'metadata': metadata,
      };
      final response = await http.post(
        Uri.parse('${AppUrl.baseUrl}/payments/create-intent'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {
        'success': false,
        'message': 'Failed to create payment intent: ${response.statusCode}',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Full payment flow (show Stripe sheet) ────────────
  // amount: in the smallest currency unit (e.g. 1000 = $10.00 USD)
  static Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String currency,
    required String description,
    Map<String, String>? metadata,
  }) async {
    try {
      final amountInCents = (amount * 100).toInt();

      final intentResult = await _createPaymentIntent(
        amountInCents: amountInCents,
        currency: currency,
        description: description,
        metadata: metadata,
      );

      if (intentResult['success'] != true) return intentResult;

      final clientSecret = intentResult['data']['clientSecret'] as String;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Torino',
          style: ThemeMode.dark,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      return {'success': true, 'message': 'Payment successful'};
    } on StripeException catch (e) {
      return {
        'success': false,
        'message': e.error.localizedMessage ?? 'Payment cancelled',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Course purchase ──────────────────────────────────
  // Price and teacherId are resolved server-side from DynamoDB.
  // The client only supplies courseId (and a display title for the description).
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

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Payment setup failed: ${response.statusCode}',
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
      return {'success': true, 'message': 'Payment successful'};
    } on StripeException catch (e) {
      return {
        'success': false,
        'message': e.error.localizedMessage ?? 'Payment cancelled',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Session booking payment ──────────────────────────
  static Future<Map<String, dynamic>> payForSession({
    required String sessionId,
    required String mentorId,
    required String mentorName,
    required double price,
  }) async {
    return processPayment(
      amount: price,
      currency: 'usd',
      description: 'Session with $mentorName',
      metadata: {
        'type': 'session_booking',
        'sessionId': sessionId,
        'mentorId': mentorId,
      },
    );
  }
}
