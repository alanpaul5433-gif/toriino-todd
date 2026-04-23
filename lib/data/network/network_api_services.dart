import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:toriino_todd/data/app_exception.dart';
import 'package:toriino_todd/data/network/base_api_services.dart';
import 'package:http/http.dart' as http;

class NetworkApiServices extends BaseApiServices {
  @override
  Future<dynamic> getGetApiResponse(
    String url, {
    Map<String, String>? headers,
  }) async {
    if (kDebugMode) {
      print(url);
    }

    dynamic responseJson;
    try {
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));
      responseJson = returnResponse(response);
    } on TimeoutException {
      throw RequestTimeOut("Request time out please try again.");
    } catch (e) {
      throw InternetException("Please check your internet connection.");
    }

    return responseJson;
  }

  @override
  Future<dynamic> getPostApiResponse(
    String url,
    dynamic data,
    Map<String, String> header,
  ) async {
    if (kDebugMode) {
      print(url);
    }

    dynamic responseJson;
    try {
      final response = await http
          .post(Uri.parse(url), body: jsonEncode(data), headers: header)
          .timeout(const Duration(seconds: 10));
      responseJson = returnResponse(response);
    } on TimeoutException {
      throw RequestTimeOut("Request time out please try again.");
    } catch (e) {
      throw InternetException("Please check your internet connection.");
    }

    return responseJson;
  }

  @override
  Future<dynamic> getPutApiResponse(
    String url,
    dynamic data, {
    Map<String, String>? headers,
  }) async {
    if (kDebugMode) {
      print(url);
    }

    dynamic responseJson;
    try {
      final response = await http
          .put(Uri.parse(url), body: jsonEncode(data), headers: headers)
          .timeout(const Duration(seconds: 10));
      responseJson = returnResponse(response);
    } on TimeoutException {
      throw RequestTimeOut("Request time out please try again.");
    } catch (e) {
      throw InternetException("Please check your internet connection.");
    }

    return responseJson;
  }

  @override
  Future<dynamic> getPatchApiResponse(
    String url,
    dynamic data, {
    Map<String, String>? headers,
  }) async {
    if (kDebugMode) {
      print(url);
    }

    dynamic responseJson;
    try {
      final response = await http
          .patch(Uri.parse(url), body: jsonEncode(data), headers: headers)
          .timeout(const Duration(seconds: 10));
      responseJson = returnResponse(response);
    } on TimeoutException {
      throw RequestTimeOut("Request time out please try again.");
    } catch (e) {
      throw InternetException("Please check your internet connection.");
    }

    return responseJson;
  }

  @override
  Future<dynamic> getDeleteApiResponse(
    String url, {
    Map<String, String>? headers,
  }) async {
    if (kDebugMode) {
      print(url);
    }

    dynamic responseJson;
    try {
      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));
      responseJson = returnResponse(response);
    } on TimeoutException {
      throw RequestTimeOut("Request time out please try again.");
    } catch (e) {
      throw InternetException("Please check your internet connection.");
    }

    return responseJson;
  }

  dynamic returnResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        dynamic responseJson = jsonDecode(response.body);
        return responseJson;
      case 204:
        return {};
      case 400:
        throw InvalidUrlException("Bad request");
      case 401:
        throw ServerException("Unauthorized. Please login again.");
      case 403:
        throw ServerException("Access denied.");
      case 404:
        throw InvalidUrlException("Resource not found");
      case 500:
        throw ServerException("Internal server error. Please try again later.");
      default:
        throw FetchdataException(
          "Error while communicating with server: ${response.statusCode}",
        );
    }
  }
}
