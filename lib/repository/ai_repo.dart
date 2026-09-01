import 'package:toriino_todd/data/appURL/app_url.dart';
import 'package:toriino_todd/data/network/auth_interceptor.dart';
import 'package:toriino_todd/data/network/network_api_services.dart';
import 'package:toriino_todd/model/ai/ai_twin_model.dart';
import 'package:toriino_todd/model/ai/chat_message_model.dart';
import 'package:toriino_todd/model/ai/session_summary_model.dart';
import 'package:toriino_todd/model/ai/transcript_model.dart';

class AiRepo {
  static final _api = NetworkApiServices();

  // ── Session summaries ─────────────────────────────────────

  static Future<void> saveSessionSummary(SessionSummaryModel summary) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    await _api.getPostApiResponse(
      AppUrl.sessionSummary(summary.sessionId),
      summary.toJson(),
      headers,
    );
  }

  static Future<SessionSummaryModel?> getSessionSummary(
      String sessionId) async {
    try {
      final headers = await AuthInterceptor.getAuthHeaders();
      final res = await _api.getGetApiResponse(
        AppUrl.sessionSummary(sessionId),
        headers: headers,
      );
      return SessionSummaryModel.fromJson(res as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ── Transcripts ───────────────────────────────────────────

  static Future<void> saveTranscript(TranscriptModel transcript) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    await _api.getPostApiResponse(
      AppUrl.sessionTranscript(transcript.sessionId),
      transcript.toJson(),
      headers,
    );
  }

  // ── Chat history ──────────────────────────────────────────

  static Future<void> saveChatMessage({
    required String userId,
    required ChatMessageModel message,
  }) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    await _api.getPostApiResponse(
      AppUrl.aiChat(userId),
      message.toJson(),
      headers,
    );
  }

  static Future<List<ChatMessageModel>> getChatHistory(String userId) async {
    try {
      final headers = await AuthInterceptor.getAuthHeaders();
      final res = await _api.getGetApiResponse(
        AppUrl.aiChat(userId),
        headers: headers,
      );
      final list = res as List;
      return list
          .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── AI Twins ──────────────────────────────────────────────

  static Future<void> saveTwin(AiTwinModel twin) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    await _api.getPostApiResponse(
      AppUrl.aiTwin(twin.userId),
      twin.toJson(),
      headers,
    );
  }

  static Future<AiTwinModel?> getTwin(String userId) async {
    try {
      final headers = await AuthInterceptor.getAuthHeaders();
      final res = await _api.getGetApiResponse(
        AppUrl.aiTwin(userId),
        headers: headers,
      );
      return AiTwinModel.fromJson(res as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ── User AI memory (progress, activity, preferences) ─────

  static Future<void> updateUserMemory({
    required String userId,
    required Map<String, dynamic> memoryData,
  }) async {
    final headers = await AuthInterceptor.getAuthHeaders();
    await _api.getPostApiResponse(
      AppUrl.aiMemory(userId),
      memoryData,
      headers,
    );
  }

  static Future<Map<String, dynamic>> getUserMemory(String userId) async {
    try {
      final headers = await AuthInterceptor.getAuthHeaders();
      final res = await _api.getGetApiResponse(
        AppUrl.aiMemory(userId),
        headers: headers,
      );
      return res as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
