import 'package:toriino_todd/data/appURL/app_url.dart';
import 'package:toriino_todd/data/network/auth_interceptor.dart';
import 'package:toriino_todd/data/network/network_api_services.dart';

class EarningsRepo {
  final _apiServices = NetworkApiServices();

  Future<dynamic> getEarningsSummary() async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getGetApiResponse(
      AppUrl.earnings,
      headers: headers,
    );
  }

  Future<dynamic> getEarningsHistory() async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getGetApiResponse(
      AppUrl.earningsHistory,
      headers: headers,
    );
  }
}
