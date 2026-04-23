import 'package:toriino_todd/data/appURL/app_url.dart';
import 'package:toriino_todd/data/network/auth_interceptor.dart';
import 'package:toriino_todd/data/network/network_api_services.dart';

class CourseRepo {
  final _apiServices = NetworkApiServices();

  Future<dynamic> getCourses({String? category}) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    String url = AppUrl.courses;
    if (category != null) url += '?category=$category';
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
