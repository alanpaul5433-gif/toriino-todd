import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:toriino_todd/config/aws_config.dart';
import 'package:toriino_todd/services/auth_service.dart';

class DynamoService {
  static const String _apiBase = AWSConfig.apiEndpoint;

  // ── Helper: Auth Headers ─────────────────────────────
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ══════════════════════════════════════════════════════
  //  USER
  // ══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> createUser({
    required String userId,
    required String name,
    required String email,
    required String role,
    String? profilePicture,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBase/users'),
        headers: await _headers(),
        body: jsonEncode({
          'userId': userId,
          'name': name,
          'email': email,
          'role': role,
          'profilePicture': profilePicture ?? '',
          'createdAt': DateTime.now().toIso8601String(),
        }),
      );
      return _parse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getUser(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBase/users/$userId'),
        headers: await _headers(),
      );
      return _parse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateUser({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiBase/users/$userId'),
        headers: await _headers(),
        body: jsonEncode(updates),
      );
      return _parse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ══════════════════════════════════════════════════════
  //  COURSES
  // ══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getCourses() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBase/courses'),
        headers: await _headers(),
      );
      return _parse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getCourseById(String courseId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBase/courses/$courseId'),
        headers: await _headers(),
      );
      return _parse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createCourse({
    required String teacherId,
    required String title,
    required String description,
    required double price,
    String? thumbnailUrl,
    String? category,
  }) async {
    try {
      final courseId =
          'course_${DateTime.now().millisecondsSinceEpoch}';
      final response = await http.post(
        Uri.parse('$_apiBase/courses'),
        headers: await _headers(),
        body: jsonEncode({
          'courseId': courseId,
          'teacherId': teacherId,
          'title': title,
          'description': description,
          'price': price,
          'thumbnailUrl': thumbnailUrl ?? '',
          'category': category ?? 'General',
          'createdAt': DateTime.now().toIso8601String(),
          'status': 'active',
        }),
      );
      return _parse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getTeacherCourses(
      String teacherId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBase/courses?teacherId=$teacherId'),
        headers: await _headers(),
      );
      return _parse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ══════════════════════════════════════════════════════
  //  SESSIONS
  // ══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getSessions({
    String? userId,
    String? role,
  }) async {
    try {
      String query = '';
      if (userId != null) query += 'userId=$userId';
      if (role != null) query += '${query.isEmpty ? '' : '&'}role=$role';

      final response = await http.get(
        Uri.parse('$_apiBase/sessions${query.isEmpty ? '' : '?$query'}'),
        headers: await _headers(),
      );
      return _parse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> bookSession({
    required String studentId,
    required String mentorId,
    required String dateTime,
    required double price,
  }) async {
    try {
      final sessionId =
          'session_${DateTime.now().millisecondsSinceEpoch}';
      final response = await http.post(
        Uri.parse('$_apiBase/sessions'),
        headers: await _headers(),
        body: jsonEncode({
          'sessionId': sessionId,
          'studentId': studentId,
          'mentorId': mentorId,
          'dateTime': dateTime,
          'price': price,
          'status': 'pending',
          'createdAt': DateTime.now().toIso8601String(),
        }),
      );
      return _parse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ══════════════════════════════════════════════════════
  //  MENTORS
  // ══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getMentors() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBase/mentors'),
        headers: await _headers(),
      );
      return _parse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ══════════════════════════════════════════════════════
  //  EARNINGS
  // ══════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getEarnings(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBase/earnings/$userId'),
        headers: await _headers(),
      );
      return _parse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ══════════════════════════════════════════════════════
  //  HELPER
  // ══════════════════════════════════════════════════════

  static Map<String, dynamic> _parse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': body};
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Request failed',
        };
      }
    } catch (_) {
      return {
        'success': false,
        'message': 'Invalid response from server',
      };
    }
  }
}
