import 'package:getxmvvm/data/appURL/app_url.dart';
import 'package:getxmvvm/data/network/auth_interceptor.dart';
import 'package:getxmvvm/data/network/network_api_services.dart';

class SessionRepo {
  final _apiServices = NetworkApiServices();

  Future<dynamic> getSessions({String role = 'student'}) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getGetApiResponse(
      '${AppUrl.sessions}?role=$role',
      headers: headers,
    );
  }

  Future<dynamic> getSessionById(String sessionId) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getGetApiResponse(
      AppUrl.sessionById(sessionId),
      headers: headers,
    );
  }

  Future<dynamic> bookSession(Map<String, dynamic> data) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getPostApiResponse(
      AppUrl.sessions,
      data,
      headers,
    );
  }

  Future<dynamic> updateSession(
      String sessionId, Map<String, dynamic> data) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getPutApiResponse(
      AppUrl.sessionById(sessionId),
      data,
      headers: headers,
    );
  }

  Future<dynamic> updateSessionStatus(
      String sessionId, String status) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getPatchApiResponse(
      AppUrl.sessionStatus(sessionId),
      {'status': status},
      headers: headers,
    );
  }
}
