import 'package:toriino_todd/data/appURL/app_url.dart';
import 'package:toriino_todd/data/network/auth_interceptor.dart';
import 'package:toriino_todd/data/network/network_api_services.dart';

class UserRepo {
  final _apiServices = NetworkApiServices();

  Future<dynamic> getProfile() async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getGetApiResponse(
      AppUrl.userProfile,
      headers: headers,
    );
  }

  Future<dynamic> updateProfile(Map<String, dynamic> data) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getPutApiResponse(
      AppUrl.userProfile,
      data,
      headers: headers,
    );
  }

  Future<dynamic> updateRole(Map<String, dynamic> data) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getPutApiResponse(
      AppUrl.userRole,
      data,
      headers: headers,
    );
  }

  Future<dynamic> deleteAccount() async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getDeleteApiResponse(
      AppUrl.deleteAccount,
      headers: headers,
    );
  }
}
