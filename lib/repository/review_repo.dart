import 'package:toriino_todd/data/appURL/app_url.dart';
import 'package:toriino_todd/data/network/auth_interceptor.dart';
import 'package:toriino_todd/data/network/network_api_services.dart';

class ReviewRepo {
  final _apiServices = NetworkApiServices();

  Future<dynamic> getReviews(String targetId) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getGetApiResponse(
      AppUrl.reviewsByTarget(targetId),
      headers: headers,
    );
  }

  Future<dynamic> submitReview(Map<String, dynamic> data) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getPostApiResponse(
      AppUrl.reviews,
      data,
      headers,
    );
  }
}
