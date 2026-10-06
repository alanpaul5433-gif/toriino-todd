// Tests for the JWT parsing logic used by AuthService.isAccessTokenExpired().
//
// NOTE: isAccessTokenExpired() itself reads from FlutterSecureStorage, which
// requires platform channels and cannot run in a pure Dart unit test host.
// These tests validate the JWT decode algorithm inline — same logic as in
// AuthService — without touching the storage layer.  To test the full method
// end-to-end, run on a real device or emulator.

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Builds a minimal, unsigned JWT with the given `exp` epoch second.
  String makeJwt(int expSeconds) {
    final header =
        base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
    final payload = base64Url
        .encode(utf8.encode('{"sub":"test-user","exp":$expSeconds}'));
    // Signature is not validated in the app — a placeholder is fine here.
    return '$header.$payload.fakesig';
  }

  // Mirrors the decode logic in AuthService.isAccessTokenExpired().
  bool jwtIsExpiredOrExpiringSoon(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return true;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      final exp = payload['exp'] as int?;
      if (exp == null) return false;
      return DateTime.now().millisecondsSinceEpoch ~/ 1000 > exp - 60;
    } catch (_) {
      return true;
    }
  }

  group('JWT expiry logic', () {
    test('token with exp far in the future is not expired', () {
      final exp =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600; // +1 h
      final jwt = makeJwt(exp);
      expect(jwtIsExpiredOrExpiringSoon(jwt), isFalse);
    });

    test('token with exp within 60 seconds is considered expired', () {
      final exp =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 30; // 30 s away
      final jwt = makeJwt(exp);
      expect(jwtIsExpiredOrExpiringSoon(jwt), isTrue);
    });

    test('token with exp already in the past is expired', () {
      final exp =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 100; // -100 s
      final jwt = makeJwt(exp);
      expect(jwtIsExpiredOrExpiringSoon(jwt), isTrue);
    });

    test('malformed token (single segment) returns true', () {
      expect(jwtIsExpiredOrExpiringSoon('notavalidjwt'), isTrue);
    });

    test('decoded payload contains expected sub claim', () {
      final exp =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600;
      final jwt = makeJwt(exp);
      final parts = jwt.split('.');
      final decoded = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      expect(decoded['sub'], 'test-user');
      expect(decoded['exp'], exp);
    });
  });
}
