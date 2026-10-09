import 'package:toriino_todd/data/appURL/app_url.dart';
import 'package:toriino_todd/data/network/auth_interceptor.dart';
import 'package:toriino_todd/data/network/network_api_services.dart';
import 'package:toriino_todd/model/subscription/subscription_model.dart';

/// Subscription endpoints. The client only ever sends a planId — prices,
/// savings and premium state are owned by the server.
class SubscriptionRepo {
  final _apiServices = NetworkApiServices();

  /// GET /subscriptions/plans (defaults to the caller's role).
  Future<SubscriptionPlansResponse> getPlans({String? audience}) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    var uri = Uri.parse(AppUrl.subscriptionPlans);
    if (audience != null && audience.isNotEmpty) {
      uri = uri.replace(queryParameters: {'audience': audience});
    }
    final value =
        await _apiServices.getGetApiResponse(uri.toString(), headers: headers);
    return SubscriptionPlansResponse.fromJson(value);
  }

  /// GET /subscriptions/me — the only source of truth for premium.
  Future<SubscriptionStatus> getMine() async {
    final headers = await AuthInterceptor.getAuthHeaders();
    final value = await _apiServices.getGetApiResponse(
      AppUrl.subscriptionMe,
      headers: headers,
    );
    return SubscriptionStatus.fromJson(value);
  }

  /// POST /subscriptions { planId } → clientSecret for the PaymentSheet.
  /// Throws the server's message on 503/403/404/409.
  Future<SubscriptionCheckout> subscribe(String planId) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    final value = await _apiServices.getPostApiResponse(
      AppUrl.subscriptions,
      {'planId': planId},
      headers,
    );
    return SubscriptionCheckout.fromJson(value);
  }

  /// POST /subscriptions/cancel → 202 { message } (cancels at period end).
  Future<String?> cancel() async {
    final headers = await AuthInterceptor.getAuthHeaders();
    final value = await _apiServices.getPostApiResponse(
      AppUrl.subscriptionCancel,
      const <String, dynamic>{},
      headers,
    );
    if (value is Map) {
      final msg = value['message'];
      if (msg is String && msg.trim().isNotEmpty) return msg;
    }
    return null;
  }
}
