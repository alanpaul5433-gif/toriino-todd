import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:toriino_todd/config/app_config.dart';
import 'package:toriino_todd/config/aws_config.dart';
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
  }) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse('${AWSConfig.apiEndpoint}/payments/create-intent'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amountInCents,
          'currency': currency,
          'description': description,
        }),
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
  }) async {
    try {
      final amountInCents = (amount * 100).toInt();

      final intentResult = await _createPaymentIntent(
        amountInCents: amountInCents,
        currency: currency,
        description: description,
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
  static Future<Map<String, dynamic>> purchaseCourse({
    required String courseId,
    required String courseTitle,
    required double price,
  }) async {
    return processPayment(
      amount: price,
      currency: 'usd',
      description: 'Course: $courseTitle',
    );
  }

  // ── Session booking payment ──────────────────────────
  static Future<Map<String, dynamic>> payForSession({
    required String sessionId,
    required String mentorName,
    required double price,
  }) async {
    return processPayment(
      amount: price,
      currency: 'usd',
      description: 'Session with $mentorName',
    );
  }
}
