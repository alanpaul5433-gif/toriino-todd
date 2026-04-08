import 'package:getxmvvm/data/appURL/app_url.dart';
import 'package:getxmvvm/data/network/auth_interceptor.dart';
import 'package:getxmvvm/data/network/network_api_services.dart';

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

  Future<dynamic> getAvatarUploadUrl(Map<String, dynamic> data) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getPostApiResponse(
      AppUrl.userAvatar,
      data,
      headers,
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
