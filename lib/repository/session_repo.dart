import 'package:toriino_todd/data/appURL/app_url.dart';
import 'package:toriino_todd/data/network/auth_interceptor.dart';
import 'package:toriino_todd/data/network/network_api_services.dart';

class SessionRepo {
  final _apiServices = NetworkApiServices();

  Future<dynamic> getSessions({String role = 'student'}) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getGetApiResponse(
      '${AppUrl.sessions}?role=$role',
      headers: headers,
    );
  }

  Future<dynamic> getSessionById(String sessionId) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getGetApiResponse(
      AppUrl.sessionById(sessionId),
      headers: headers,
    );
  }

  Future<dynamic> bookSession(Map<String, dynamic> data) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getPostApiResponse(
      AppUrl.sessions,
      data,
      headers,
    );
  }

  Future<dynamic> updateSession(
      String sessionId, Map<String, dynamic> data) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getPutApiResponse(
      AppUrl.sessionById(sessionId),
      data,
      headers: headers,
    );
  }

  Future<dynamic> updateSessionStatus(
      String sessionId, String status) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    return await _apiServices.getPatchApiResponse(
      AppUrl.sessionStatus(sessionId),
      {'status': status},
      headers: headers,
    );
  }

  Future<Map<String, dynamic>> fetchAgoraToken(
      String channelName, {int uid = 0, String role = 'publisher'}) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    final result = await _apiServices.getPostApiResponse(
      AppUrl.agoraToken,
      {'channelName': channelName, 'uid': uid, 'role': role},
      headers,
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> startRecording(String sessionId, {String agoraToken = '', int uid = 0}) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    final result = await _apiServices.getPostApiResponse(
      AppUrl.startRecording(sessionId),
      {'agoraToken': agoraToken, 'uid': uid},
      headers,
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> stopRecording(String sessionId, {int uid = 0}) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    final result = await _apiServices.getPostApiResponse(
      AppUrl.stopRecording(sessionId),
      {'uid': uid},
      headers,
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<void> saveTranscript(String sessionId, Map<String, dynamic> transcriptData) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    await _apiServices.getPostApiResponse(
      AppUrl.sessionTranscript(sessionId),
      transcriptData,
      headers,
    );
  }

  Future<Map<String, dynamic>> generateSummary(String sessionId, String transcriptText, {String subjectArea = 'general'}) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    final result = await _apiServices.getPostApiResponse(
      AppUrl.sessionSummary(sessionId),
      {'transcript': transcriptText, 'subjectArea': subjectArea},
      headers,
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>?> getSummary(String sessionId) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    try {
      final result = await _apiServices.getGetApiResponse(
        AppUrl.sessionSummary(sessionId),
        headers: headers,
      );
      return Map<String, dynamic>.from(result as Map);
    } catch (_) { return null; }
  }
}
