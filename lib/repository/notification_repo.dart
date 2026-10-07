import 'package:toriino_todd/data/appURL/app_url.dart';
import 'package:toriino_todd/data/network/auth_interceptor.dart';
import 'package:toriino_todd/data/network/network_api_services.dart';

class NotificationRepo {
  final _apiServices = NetworkApiServices();

  Future<dynamic> getNotifications() async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getGetApiResponse(
      AppUrl.notifications,
      headers: headers,
    );
  }

  Future<dynamic> markAsRead(String sortKey) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getPatchApiResponse(
      AppUrl.markNotificationRead(sortKey),
      {},
      headers: headers,
    );
  }

  /// POST /notifications/fcm-token with {token, platform}.
  /// [platform] is 'android' or 'ios'.
  Future<dynamic> registerFcmToken(String token, {required String platform}) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getPostApiResponse(
      AppUrl.registerFcmToken,
      {'token': token, 'platform': platform},
      headers,
    );
  }
}
