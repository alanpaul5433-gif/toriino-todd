import 'dart:convert';
import 'package:toriino_todd/services/auth_service.dart';

class AuthInterceptor {
  /// Returns headers with Authorization Bearer token for authenticated requests.
  /// Auto-refreshes the token if it is within 60 seconds of expiry.
  static Future<Map<String, String>> getAuthHeaders() async {
    String? token = await AuthService.getToken();

    if (token != null && _isTokenExpired(token)) {
      token = await AuthService.refreshSession() ?? token;
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  static bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return false;
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      final exp = payload['exp'] as int?;
      if (exp == null) return false;
      // Refresh if token expires within 60 seconds
      return DateTime.now().millisecondsSinceEpoch ~/ 1000 > exp - 60;
    } catch (_) {
      return false;
    }
  }

  /// Returns headers without auth token for public endpoints (login, register).
  static Map<String, String> getPublicHeaders() {
    return {
      'Content-Type': 'application/json',
    };
  }
}
