import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:toriino_todd/data/appURL/app_url.dart';
import 'package:toriino_todd/model/ai/ai_twin_model.dart';
import 'package:toriino_todd/model/ai/session_summary_model.dart';
import 'package:toriino_todd/services/ai_interface.dart';
import 'package:toriino_todd/services/auth_service.dart';

class LambdaAiService implements AiInterface {
  // ── Singleton ────────────────────────────────────────
  static LambdaAiService? _instance;
  static LambdaAiService get instance => _instance ??= LambdaAiService();

  // ── Helpers ──────────────────────────────────────────
  Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<String> _getUserId() async {
    return await AuthService.getUserId() ?? 'unknown';
  }

  String _parseTextResponse(Map<String, dynamic> json) {
    return (json['message'] ?? json['response'] ?? '') as String;
  }

  // ── AiInterface implementation ───────────────────────

  @override
  Future<String> ask(String question, {String? context}) async {
    try {
      final userId = await _getUserId();
      final headers = await _headers();
      final body = <String, dynamic>{
        'message': context != null ? 'Context: $context\n\nQuestion: $question' : question,
      };
      final response = await http.post(
        Uri.parse(AppUrl.aiChat(userId)),
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return _parseTextResponse(json);
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  @override
  Future<String> chat(String message, {List<String> history = const []}) async {
    try {
      final userId = await _getUserId();
      final headers = await _headers();
      final body = <String, dynamic>{
        'message': message,
        if (history.isNotEmpty) 'history': history,
      };
      final response = await http.post(
        Uri.parse(AppUrl.aiChat(userId)),
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return _parseTextResponse(json);
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  @override
  Future<SessionSummaryModel> summarizeSession({
    required String sessionId,
    required String transcript,
    String? subjectArea,
  }) async {
    try {
      final headers = await _headers();
      final body = <String, dynamic>{
        'transcript': transcript,
        if (subjectArea != null) 'subjectArea': subjectArea,
      };
      final response = await http.post(
        Uri.parse(AppUrl.sessionSummary(sessionId)),
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return SessionSummaryModel(
          sessionId: sessionId,
          summary: json['summary'] ?? '',
          actionItems: List<String>.from(json['actionItems'] ?? []),
          keyTopics: List<String>.from(json['keyTopics'] ?? []),
          insights: List<String>.from(json['insights'] ?? []),
          transcript: transcript,
          generatedAt: DateTime.now(),
        );
      }
    } catch (_) {}
    return SessionSummaryModel(
      sessionId: sessionId,
      summary: '',
      actionItems: [],
      keyTopics: [],
      insights: [],
      transcript: transcript,
      generatedAt: DateTime.now(),
    );
  }

  @override
  Future<String> generateCourseOutline(String topic, {int numModules = 6}) async {
    return chat(
      'Generate a structured course outline for: "$topic". '
      'Include $numModules modules with a title and 3-4 lesson ideas each. '
      'Format as a numbered list.',
    );
  }

  @override
  Future<String> summarizeReviews(List<String> reviews) async {
    if (reviews.isEmpty) return 'No reviews yet.';
    final joined = reviews.map((r) => '- $r').join('\n');
    return chat(
      'Summarize these student reviews in 2-3 sentences, highlighting strengths '
      'and areas for improvement:\n$joined',
    );
  }

  @override
  Future<AiTwinModel> buildAiTwin({
    required String userId,
    required String role,
    required String name,
    required String bio,
    required List<String> recentTranscripts,
  }) async {
    try {
      final headers = await _headers();
      final body = <String, dynamic>{
        'role': role,
        'name': name,
        'bio': bio,
        'recentTranscripts': recentTranscripts,
      };
      final response = await http.post(
        Uri.parse(AppUrl.aiTwin(userId)),
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AiTwinModel(
          userId: userId,
          role: role,
          name: name,
          personalityProfile: json['personalityProfile'] ?? '',
          expertiseAreas: List<String>.from(json['expertiseAreas'] ?? []),
          teachingStyle: List<String>.from(json['teachingStyle'] ?? []),
          knowledgeMemory: {},
          lastUpdated: DateTime.now(),
        );
      }
    } catch (_) {}
    return AiTwinModel(
      userId: userId,
      role: role,
      name: name,
      personalityProfile: bio,
      expertiseAreas: [],
      teachingStyle: [],
      knowledgeMemory: {},
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Future<String> askTwin({
    required AiTwinModel twin,
    required String question,
    List<String> history = const [],
  }) async {
    try {
      final headers = await _headers();
      final body = <String, dynamic>{
        'question': question,
        if (history.isNotEmpty) 'history': history,
      };
      final response = await http.post(
        Uri.parse(AppUrl.aiTwin(twin.userId)),
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return _parseTextResponse(json);
      }
    } catch (_) {}
    return '';
  }
}
