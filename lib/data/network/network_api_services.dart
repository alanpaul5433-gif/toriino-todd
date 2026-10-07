import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:toriino_todd/data/app_exception.dart';
import 'package:toriino_todd/data/network/base_api_services.dart';
import 'package:toriino_todd/services/auth_service.dart';
import 'package:http/http.dart' as http;

class NetworkApiServices extends BaseApiServices {
  // ── Single-flight refresh lock ────────────────────────
  // Ensures multiple concurrent 401s trigger only one token refresh.
  static Completer<String?>? _refreshCompleter;

  static Future<String?> _doRefresh() async {
    if (_refreshCompleter != null) return _refreshCompleter!.future;
    _refreshCompleter = Completer();
    final newToken = await AuthService.refreshSession();
    _refreshCompleter!.complete(newToken);
    _refreshCompleter = null;
    return newToken;
  }

  // ── Retry helper: rebuild headers with fresh token ────
  static Map<String, String> _withFreshToken(
    Map<String, String>? original,
    String token,
  ) {
    final h = Map<String, String>.from(original ?? {});
    h['Authorization'] = 'Bearer $token';
    return h;
  }

  @override
  Future<dynamic> getGetApiResponse(
    String url, {
    Map<String, String>? headers,
  }) async {
    if (kDebugMode) print(url);
    try {
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 401) {
        final newToken = await _doRefresh();
        if (newToken == null) {
          await AuthService.signOut();
          throw ServerException('Session expired. Please log in again.');
        }
        final retried = await http
            .get(Uri.parse(url), headers: _withFreshToken(headers, newToken))
            .timeout(const Duration(seconds: 10));
        return returnResponse(retried);
      }
      return returnResponse(response);
    } on TimeoutException {
      throw RequestTimeOut('Request time out please try again.');
    } on AppException {
      rethrow;
    } catch (e) {
      throw InternetException('Please check your internet connection.');
    }
  }

  @override
  Future<dynamic> getPostApiResponse(
    String url,
    dynamic data,
    Map<String, String> header,
  ) async {
    if (kDebugMode) print(url);
    final body = jsonEncode(data);
    try {
      final response = await http
          .post(Uri.parse(url), body: body, headers: header)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 401) {
        final newToken = await _doRefresh();
        if (newToken == null) {
          await AuthService.signOut();
          throw ServerException('Session expired. Please log in again.');
        }
        final retried = await http
            .post(Uri.parse(url), body: body, headers: _withFreshToken(header, newToken))
            .timeout(const Duration(seconds: 10));
        return returnResponse(retried);
      }
      return returnResponse(response);
    } on TimeoutException {
      throw RequestTimeOut('Request time out please try again.');
    } on AppException {
      rethrow;
    } catch (e) {
      throw InternetException('Please check your internet connection.');
    }
  }

  @override
  Future<dynamic> getPutApiResponse(
    String url,
    dynamic data, {
    Map<String, String>? headers,
  }) async {
    if (kDebugMode) print(url);
    final body = jsonEncode(data);
    try {
      final response = await http
          .put(Uri.parse(url), body: body, headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 401) {
        final newToken = await _doRefresh();
        if (newToken == null) {
          await AuthService.signOut();
          throw ServerException('Session expired. Please log in again.');
        }
        final retried = await http
            .put(Uri.parse(url), body: body, headers: _withFreshToken(headers, newToken))
            .timeout(const Duration(seconds: 10));
        return returnResponse(retried);
      }
      return returnResponse(response);
    } on TimeoutException {
      throw RequestTimeOut('Request time out please try again.');
    } on AppException {
      rethrow;
    } catch (e) {
      throw InternetException('Please check your internet connection.');
    }
  }

  @override
  Future<dynamic> getPatchApiResponse(
    String url,
    dynamic data, {
    Map<String, String>? headers,
  }) async {
    if (kDebugMode) print(url);
    final body = jsonEncode(data);
    try {
      final response = await http
          .patch(Uri.parse(url), body: body, headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 401) {
        final newToken = await _doRefresh();
        if (newToken == null) {
          await AuthService.signOut();
          throw ServerException('Session expired. Please log in again.');
        }
        final retried = await http
            .patch(Uri.parse(url), body: body, headers: _withFreshToken(headers, newToken))
            .timeout(const Duration(seconds: 10));
        return returnResponse(retried);
      }
      return returnResponse(response);
    } on TimeoutException {
      throw RequestTimeOut('Request time out please try again.');
    } on AppException {
      rethrow;
    } catch (e) {
      throw InternetException('Please check your internet connection.');
    }
  }

  @override
  Future<dynamic> getDeleteApiResponse(
    String url, {
    Map<String, String>? headers,
  }) async {
    if (kDebugMode) print(url);
    try {
      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 401) {
        final newToken = await _doRefresh();
        if (newToken == null) {
          await AuthService.signOut();
          throw ServerException('Session expired. Please log in again.');
        }
        final retried = await http
            .delete(Uri.parse(url), headers: _withFreshToken(headers, newToken))
            .timeout(const Duration(seconds: 10));
        return returnResponse(retried);
      }
      return returnResponse(response);
    } on TimeoutException {
      throw RequestTimeOut('Request time out please try again.');
    } on AppException {
      rethrow;
    } catch (e) {
      throw InternetException('Please check your internet connection.');
    }
  }

  dynamic returnResponse(http.Response response) {
    final code = response.statusCode;
    if (code >= 200 && code < 300) {
      if (code == 204 || response.body.trim().isEmpty) return {};
      return jsonDecode(response.body);
    }
    // Prefer the server's own error message ({error} or {message}) so the UI
    // can show the real reason (validation, policy, not found, ...).
    final serverMsg = _extractServerMessage(response.body);
    switch (code) {
      case 400:
        throw InvalidUrlException(serverMsg ?? 'Bad request');
      case 401:
        throw ServerException(serverMsg ?? 'Unauthorized. Please login again.');
      case 402:
        throw PaymentRequiredException(
          serverMsg ?? 'Payment required',
          price: _extractPrice(response.body),
        );
      case 403:
        throw ForbiddenException(serverMsg ?? 'Access denied.');
      case 404:
        throw NotFoundException(serverMsg ?? 'Resource not found');
      case 409:
        throw ConflictException(serverMsg ?? 'Conflict');
      case 500:
        throw ServerException(
          serverMsg ?? 'Internal server error. Please try again later.',
        );
      default:
        throw FetchdataException(
          serverMsg ?? 'Error while communicating with server: $code',
        );
    }
  }

  static double? _extractPrice(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['price'] is num) {
        return (decoded['price'] as num).toDouble();
      }
    } catch (_) {}
    return null;
  }

  static String? _extractServerMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final msg = decoded['error'] ?? decoded['message'];
        if (msg is String && msg.trim().isNotEmpty) return msg;
      }
    } catch (_) {}
    return null;
  }
}
