import 'package:toriino_todd/data/appURL/app_url.dart';
import 'package:toriino_todd/data/network/network_api_services.dart';

class LoginRepo {
  final _apiServices = NetworkApiServices();
  Future<dynamic> loginApi(dynamic data) async {
    dynamic response = await _apiServices.getPostApiResponse(
      AppUrl.login,
      data, {
      "x-api-key": "reqres-free-v1",
      "Content-Type": "application/json",
    }

    );

    return response;
  }
}
