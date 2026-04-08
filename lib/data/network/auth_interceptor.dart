import 'package:getxmvvm/viewmodel/controller/login/user_prefrence/users_prefrence.dart';

class AuthInterceptor {
  static final UsersPrefrence _usersPrefrence = UsersPrefrence();

  /// Returns headers with Authorization Bearer token for authenticated requests.
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await _usersPrefrence.getUser();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  /// Returns headers without auth token for public endpoints (login, register).
  static Map<String, String> getPublicHeaders() {
    return {
      'Content-Type': 'application/json',
    };
  }
}
