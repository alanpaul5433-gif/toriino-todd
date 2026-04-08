import 'package:getxmvvm/data/appURL/app_url.dart';
import 'package:getxmvvm/data/network/auth_interceptor.dart';
import 'package:getxmvvm/data/network/network_api_services.dart';

class AuthRepo {
  final _apiServices = NetworkApiServices();

  Future<dynamic> loginApi(Map<String, dynamic> data) async {
    final response = await _apiServices.getPostApiResponse(
      AppUrl.login,
      data,
      AuthInterceptor.getPublicHeaders(),
    );
    return response;
  }

  Future<dynamic> registerApi(Map<String, dynamic> data) async {
    final response = await _apiServices.getPostApiResponse(
      AppUrl.register,
      data,
      AuthInterceptor.getPublicHeaders(),
    );
    return response;
  }

  Future<dynamic> verifyEmailApi(Map<String, dynamic> data) async {
    final response = await _apiServices.getPostApiResponse(
      AppUrl.verifyEmail,
      data,
      AuthInterceptor.getPublicHeaders(),
    );
    return response;
  }

  Future<dynamic> refreshTokenApi(Map<String, dynamic> data) async {
    final response = await _apiServices.getPostApiResponse(
      AppUrl.refreshToken,
      data,
      AuthInterceptor.getPublicHeaders(),
    );
    return response;
  }

  Future<dynamic> forgotPasswordApi(Map<String, dynamic> data) async {
    final response = await _apiServices.getPostApiResponse(
      AppUrl.forgotPassword,
      data,
      AuthInterceptor.getPublicHeaders(),
    );
    return response;
  }

  Future<dynamic> resetPasswordApi(Map<String, dynamic> data) async {
    final response = await _apiServices.getPostApiResponse(
      AppUrl.resetPassword,
      data,
      AuthInterceptor.getPublicHeaders(),
    );
    return response;
  }

  Future<dynamic> setRoleApi(Map<String, dynamic> data) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    final response = await _apiServices.getPostApiResponse(
      AppUrl.setRole,
      data,
      headers,
    );
    return response;
  }

  Future<dynamic> logoutApi() async {
    final headers = await AuthInterceptor.getAuthHeaders();
    final response = await _apiServices.getPostApiResponse(
      AppUrl.logout,
      {},
      headers,
    );
    return response;
  }
}
