import 'dart:convert';
import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:toriino_todd/config/aws_config.dart';
import 'package:toriino_todd/data/appURL/app_url.dart';

class AuthService {
  static final _userPool = CognitoUserPool(
    AWSConfig.userPoolId,
    AWSConfig.clientId,
  );

  static const _storage = FlutterSecureStorage();
  static CognitoUser? _cognitoUser;
  static CognitoUserSession? _session;

  // ── Sign Up ──────────────────────────────────────────
  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      final userAttributes = [
        AttributeArg(name: 'name', value: name),
        if (phone != null && phone.isNotEmpty)
          AttributeArg(name: 'phone_number', value: _toE164(phone)),
      ];

      final result = await _userPool.signUp(
        email,
        password,
        userAttributes: userAttributes,
      );

      return {
        'success': true,
        'userConfirmed': result.userConfirmed,
        'message': 'Account created. Please check your email to verify.',
      };
    } on CognitoClientException catch (e) {
      return {'success': false, 'message': e.message ?? 'Sign up failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Confirm Sign Up (OTP) ────────────────────────────
  static Future<Map<String, dynamic>> confirmSignUp({
    required String email,
    required String code,
  }) async {
    try {
      final cognitoUser = CognitoUser(email, _userPool);
      final result = await cognitoUser.confirmRegistration(code);
      return {
        'success': result,
        'message': result ? 'Email verified successfully' : 'Verification failed',
      };
    } on CognitoClientException catch (e) {
      return {'success': false, 'message': e.message ?? 'Confirmation failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Resend Sign Up Code ──────────────────────────────
  static Future<Map<String, dynamic>> resendSignUpCode({
    required String email,
  }) async {
    try {
      final cognitoUser = CognitoUser(email, _userPool);
      await cognitoUser.resendConfirmationCode();
      return {'success': true, 'message': 'Verification code resent'};
    } on CognitoClientException catch (e) {
      return {'success': false, 'message': e.message ?? 'Resend failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Sign In ──────────────────────────────────────────
  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _cognitoUser = CognitoUser(email, _userPool);
      final authDetails = AuthenticationDetails(
        username: email,
        password: password,
      );

      _session = await _cognitoUser!.authenticateUser(authDetails);

      // Save tokens securely
      await _storage.write(
        key: 'access_token',
        value: _session!.accessToken.jwtToken,
      );
      await _storage.write(
        key: 'id_token',
        value: _session!.idToken.jwtToken,
      );
      await _storage.write(
        key: 'refresh_token',
        value: _session?.refreshToken?.token ?? '',  // P3-4: null-safe
      );

      // Decode ID token payload to extract role
      String? userRole;
      try {
        final parts = _session!.idToken.jwtToken!.split('.');
        if (parts.length == 3) {
          final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
          final claims = jsonDecode(payload) as Map<String, dynamic>;
          userRole = claims['custom:role'] as String?;
        }
      } catch (_) {}

      return {
        'success': true,
        'message': 'Login successful',
        'token': _session!.idToken.jwtToken,
        if (userRole != null) 'role': userRole,
      };
    } on CognitoClientException catch (e) {
      return {'success': false, 'message': e.message ?? 'Login failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Set Role in Cognito (P3-3) ───────────────────────
  // Calls /auth/set-role Lambda (admin sets custom:role), then refreshes
  // the session so subsequent JWT tokens carry the new claim.
  static Future<Map<String, dynamic>> setRole(String role) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'message': 'Not logged in'};

      final response = await http.post(
        Uri.parse(AppUrl.setRole),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'role': role}),
      );

      if (response.statusCode == 200) {
        await refreshSession();
        return {'success': true};
      }
      return {
        'success': false,
        'message': 'Role update failed: ${response.statusCode}',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Sign Out ─────────────────────────────────────────
  static Future<void> signOut() async {
    await _cognitoUser?.signOut();
    await _storage.deleteAll();
    _cognitoUser = null;
    _session = null;
  }

  // ── Forgot Password ──────────────────────────────────
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final cognitoUser = CognitoUser(email, _userPool);
      final data = await cognitoUser.forgotPassword();
      return {
        'success': true,
        'message': 'Reset code sent to your email',
        'data': data,
      };
    } on CognitoClientException catch (e) {
      return {'success': false, 'message': e.message ?? 'Request failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Confirm New Password ─────────────────────────────
  static Future<Map<String, dynamic>> confirmNewPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final cognitoUser = CognitoUser(email, _userPool);
      final result = await cognitoUser.confirmPassword(code, newPassword);
      return {
        'success': result,
        'message': result ? 'Password reset successful' : 'Reset failed',
      };
    } on CognitoClientException catch (e) {
      return {'success': false, 'message': e.message ?? 'Reset failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Change Password (signed-in user) ────────────────
  // Uses Cognito ChangePassword with the current access token. After an app
  // restart there is no in-memory CognitoUser, so the session is rebuilt
  // from the tokens in secure storage (and refreshed if expired).
  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final user = await _restoreCognitoUser();
      if (user == null) {
        return {
          'success': false,
          'message': 'Your session has expired. Please log in again.',
        };
      }
      await user.changePassword(oldPassword, newPassword);
      return {'success': true, 'message': 'Password changed successfully'};
    } on CognitoClientException catch (e) {
      return {
        'success': false,
        'message': _changePasswordError(e),
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static String _changePasswordError(CognitoClientException e) {
    switch (e.code) {
      case 'NotAuthorizedException':
        return 'Current password is incorrect.';
      case 'InvalidPasswordException':
        return e.message ?? 'New password does not meet the password policy.';
      case 'InvalidParameterException':
        return e.message ?? 'New password does not meet the password policy.';
      case 'LimitExceededException':
      case 'TooManyRequestsException':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Password change failed';
    }
  }

  /// Returns a CognitoUser with a valid session, restoring it from stored
  /// tokens if needed. Returns null if no usable session exists.
  static Future<CognitoUser?> _restoreCognitoUser() async {
    final current = _cognitoUser;
    final currentSession = _session;
    if (current != null && currentSession != null && currentSession.isValid()) {
      return current;
    }

    final idToken = await _storage.read(key: 'id_token');
    final accessToken = await _storage.read(key: 'access_token');
    final refreshTokenStr = await _storage.read(key: 'refresh_token');
    final email = await _getEmailFromToken();
    if (idToken == null || accessToken == null || email == null) return null;

    final refreshToken = (refreshTokenStr != null && refreshTokenStr.isNotEmpty)
        ? CognitoRefreshToken(refreshTokenStr)
        : null;
    var session = CognitoUserSession(
      CognitoIdToken(idToken),
      CognitoAccessToken(accessToken),
      refreshToken: refreshToken,
    );
    final user = CognitoUser(email, _userPool, signInUserSession: session);

    if (!session.isValid()) {
      if (refreshToken == null) return null;
      final refreshed = await user.refreshSession(refreshToken);
      if (refreshed == null || !refreshed.isValid()) return null;
      session = refreshed;
      await _storage.write(key: 'id_token', value: session.idToken.jwtToken);
      await _storage.write(
        key: 'access_token',
        value: session.accessToken.jwtToken,
      );
    }

    _cognitoUser = user;
    _session = session;
    return user;
  }

  // ── Check if Logged In ───────────────────────────────
  static Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null && token.isNotEmpty;
  }

  // ── Check if Access Token is Expired ────────────────
  static Future<bool> isAccessTokenExpired() async {
    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null || token.isEmpty) return true;
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

  // ── Get Saved Token ──────────────────────────────────
  static Future<String?> getToken() async {
    return await _storage.read(key: 'id_token');
  }

  // ── Refresh Session using stored refresh_token ───────
  static Future<String?> refreshSession() async {
    try {
      final refreshTokenStr = await _storage.read(key: 'refresh_token');
      final email = await _getEmailFromToken();
      if (refreshTokenStr == null || refreshTokenStr.isEmpty || email == null) return null;

      final cognitoUser = CognitoUser(email, _userPool);
      final refreshToken = CognitoRefreshToken(refreshTokenStr);
      final session = await cognitoUser.refreshSession(refreshToken);
      if (session == null) return null;

      await _storage.write(key: 'id_token', value: session.idToken.jwtToken);
      await _storage.write(key: 'access_token', value: session.accessToken.jwtToken);
      return session.idToken.jwtToken;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _getEmailFromToken() async {
    try {
      final token = await _storage.read(key: 'id_token');
      if (token == null) return null;
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payload = json.decode(utf8.decode(base64Url.decode(normalized)));
      return payload['email'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Get Cognito User ID (sub claim from id_token) ────
  static Future<String?> getUserId() async {
    try {
      final token = await _storage.read(key: 'id_token');
      if (token == null) return null;
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payload = json.decode(utf8.decode(base64Url.decode(normalized)));
      return payload['sub'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Helper: normalize phone to E.164 ────────────────
  static String _toE164(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (phone.startsWith('+')) return '+$digits';
    if (digits.length == 10) return '+1$digits'; // assume US
    return '+$digits';
  }
}
