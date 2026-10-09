import 'package:toriino_todd/data/appURL/app_url.dart';
import 'package:toriino_todd/data/network/auth_interceptor.dart';
import 'package:toriino_todd/data/network/network_api_services.dart';

class MentorRepo {
  final _apiServices = NetworkApiServices();

  Future<dynamic> getMentors({String? expertise}) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    String url = AppUrl.mentors;
    if (expertise != null) url += '?expertise=$expertise';
    return await _apiServices.getGetApiResponse(url, headers: headers);
  }

  Future<dynamic> getMentorById(String mentorId) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getGetApiResponse(
      AppUrl.mentorById(mentorId),
      headers: headers,
    );
  }

  Future<dynamic> getAvailability(String mentorId) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getGetApiResponse(
      AppUrl.mentorAvailability(mentorId),
      headers: headers,
    );
  }

  Future<dynamic> updateAvailability(Map<String, dynamic> data) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getPutApiResponse(
      AppUrl.updateAvailability,
      data,
      headers: headers,
    );
  }
}
