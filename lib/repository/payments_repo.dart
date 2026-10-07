import 'package:toriino_todd/data/appURL/app_url.dart';
import 'package:toriino_todd/data/network/auth_interceptor.dart';
import 'package:toriino_todd/data/network/network_api_services.dart';
import 'package:toriino_todd/model/payment/pricing_model.dart';

/// Server quotes and payment intents. All amounts come from the server; the
/// app only displays them.
class PaymentsRepo {
  final _apiServices = NetworkApiServices();

  Future<PaymentQuoteModel> _quote(Map<String, String> query) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    final uri = Uri.parse(AppUrl.paymentsQuote).replace(queryParameters: query);
    final value = await _apiServices.getGetApiResponse(
      uri.toString(),
      headers: headers,
    );
    return PaymentQuoteModel.fromJson(
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{},
    );
  }

  /// GET /payments/quote?courseId=…
  Future<PaymentQuoteModel> quoteForCourse(String courseId) =>
      _quote({'courseId': courseId});

  /// GET /payments/quote?mentorId=…&duration=… (before booking).
  Future<PaymentQuoteModel> quoteForMentor(String mentorId,
          {required int durationMinutes}) =>
      _quote({'mentorId': mentorId, 'duration': '$durationMinutes'});

  /// GET /payments/quote?sessionId=… (after booking; caller is the student).
  Future<PaymentQuoteModel> quoteForSession(String sessionId) =>
      _quote({'sessionId': sessionId});

  /// POST /payments/create-intent { type: session_booking, sessionId,
  /// useWallet: true }. Either the wallet pays the full price
  /// (`paidWithWallet`) or a `clientSecret` for the full price is returned.
  Future<SessionPaymentIntent> createSessionIntent(String sessionId,
      {bool useWallet = true}) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    final value = await _apiServices.getPostApiResponse(
      AppUrl.paymentsCreateIntent,
      {
        'type': 'session_booking',
        'sessionId': sessionId,
        'useWallet': useWallet,
      },
      headers,
    );
    return SessionPaymentIntent.fromJson(
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{},
    );
  }
}
