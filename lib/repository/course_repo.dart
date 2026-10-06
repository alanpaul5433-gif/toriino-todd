import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:toriino_todd/data/appURL/app_url.dart';
import 'package:toriino_todd/data/network/auth_interceptor.dart';
import 'package:toriino_todd/data/network/network_api_services.dart';

class CourseRepo {
  final _apiServices = NetworkApiServices();

  Future<dynamic> getCourses({String? category, String? lastKey}) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    String url = AppUrl.courses;
    final params = <String>[];
    if (category != null) params.add('category=$category');
    if (lastKey != null) params.add('lastKey=${Uri.encodeComponent(lastKey)}');
    if (params.isNotEmpty) url += '?${params.join('&')}';
    return await _apiServices.getGetApiResponse(url, headers: headers);
  }

  Future<dynamic> getCourseById(String courseId) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getGetApiResponse(
      AppUrl.courseById(courseId),
      headers: headers,
    );
  }

  Future<dynamic> createCourse(Map<String, dynamic> data) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getPostApiResponse(AppUrl.courses, data, headers);
  }

  Future<dynamic> updateCourse(
      String courseId, Map<String, dynamic> data) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getPutApiResponse(
      AppUrl.courseById(courseId),
      data,
      headers: headers,
    );
  }

  Future<dynamic> deleteCourse(String courseId) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getDeleteApiResponse(
      AppUrl.courseById(courseId),
      headers: headers,
    );
  }

  Future<dynamic> getLessons(String courseId) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getGetApiResponse(
      AppUrl.courseLessons(courseId),
      headers: headers,
    );
  }

  Future<dynamic> addLesson(
      String courseId, Map<String, dynamic> data) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getPostApiResponse(
      AppUrl.courseLessons(courseId),
      data,
      headers,
    );
  }

  Future<dynamic> updateLesson(
      String courseId, String lessonId, Map<String, dynamic> data) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getPutApiResponse(
      AppUrl.courseLesson(courseId, lessonId),
      data,
      headers: headers,
    );
  }

  Future<dynamic> deleteLesson(String courseId, String lessonId) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getDeleteApiResponse(
      AppUrl.courseLesson(courseId, lessonId),
      headers: headers,
    );
  }

  /// Requests a presigned S3 PUT URL for uploading a lesson material file.
  /// Returns a Map with keys: uploadUrl, url (public S3 URL), key.
  Future<Map<String, dynamic>> getUploadUrl({
    required String fileName,
    required String contentType,
    required String courseId,
  }) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    final uri = Uri.parse(AppUrl.courseUploadUrl).replace(queryParameters: {
      'fileName': fileName,
      'contentType': contentType,
      'courseId': courseId,
    });
    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Failed to get upload URL: ${response.statusCode}');
    }
    return Map<String, dynamic>.from(
      (response.body.isNotEmpty ? jsonDecode(response.body) : {}) as Map,
    );
  }

  /// Uploads raw file bytes directly to S3 via a presigned PUT URL.
  Future<void> uploadFileToS3({
    required String presignedUrl,
    required Uint8List bytes,
    required String contentType,
    void Function(double progress)? onProgress,
  }) async {
    final request = http.Request('PUT', Uri.parse(presignedUrl));
    request.headers['Content-Type'] = contentType;
    request.bodyBytes = bytes;
    final streamedResponse = await request.send().timeout(const Duration(minutes: 10));
    if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
      throw Exception('S3 upload failed: ${streamedResponse.statusCode}');
    }
  }

  Future<dynamic> enrollCourse(String courseId) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getPostApiResponse(
      AppUrl.enrollCourse(courseId),
      {},
      headers,
    );
  }

  Future<dynamic> getMyEnrolledCourses() async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getGetApiResponse(
      AppUrl.myCourses,
      headers: headers,
    );
  }

  Future<dynamic> getMyCreatedCourses() async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getGetApiResponse(
      AppUrl.myCreatedCourses,
      headers: headers,
    );
  }
}
