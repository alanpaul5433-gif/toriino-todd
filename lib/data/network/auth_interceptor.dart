import 'package:toriino_todd/services/auth_service.dart';

class AuthInterceptor {
  /// Returns headers with Authorization Bearer token for authenticated requests.
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await AuthService.getToken();
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
