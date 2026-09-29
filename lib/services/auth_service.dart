import 'dart:convert';
import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:toriino_todd/config/aws_config.dart';

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
    required String role, // Student / Teacher / Mentor
  }) async {
    try {
      final userAttributes = [
        AttributeArg(name: 'name', value: name),
        AttributeArg(name: 'custom:role', value: role),
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
        value: _session!.refreshToken!.token,
      );

      return {
        'success': true,
        'message': 'Login successful',
        'token': _session!.idToken.jwtToken,
      };
    } on CognitoClientException catch (e) {
      return {'success': false, 'message': e.message ?? 'Login failed'};
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

  // ── Check if Logged In ───────────────────────────────
  static Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }

  // ── Get Saved Token ──────────────────────────────────
  static Future<String?> getToken() async {
    return await _storage.read(key: 'id_token');
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
}
