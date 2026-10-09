// GeminiService is now a thin wrapper around LambdaAiService.
// The Gemini API key is no longer embedded in the binary — all AI calls
// go through the Lambda proxy instead.
import 'package:toriino_todd/model/ai/ai_twin_model.dart';
import 'package:toriino_todd/model/ai/session_summary_model.dart';
import 'package:toriino_todd/services/ai_interface.dart';
import 'package:toriino_todd/services/lambda_ai_service.dart';

class GeminiService implements AiInterface {
  // ── Singleton ────────────────────────────────────────
  static GeminiService? _instance;
  static GeminiService get instance => _instance ??= GeminiService();

  final AiInterface _delegate = LambdaAiService.instance;

  // ── AiInterface delegation ───────────────────────────

  @override
  Future<String> ask(String question, {String? context}) =>
      _delegate.ask(question, context: context);

  @override
  Future<String> chat(String message, {List<String> history = const []}) =>
      _delegate.chat(message, history: history);

  @override
  Future<SessionSummaryModel> summarizeSession({
    required String sessionId,
    required String transcript,
    String? subjectArea,
  }) =>
      _delegate.summarizeSession(
        sessionId: sessionId,
        transcript: transcript,
        subjectArea: subjectArea,
      );

  @override
  Future<String> generateCourseOutline(String topic, {int numModules = 6}) =>
      _delegate.generateCourseOutline(topic, numModules: numModules);

  @override
  Future<String> summarizeReviews(List<String> reviews) =>
      _delegate.summarizeReviews(reviews);

  @override
  Future<AiTwinModel> buildAiTwin({
    required String userId,
    required String role,
    required String name,
    required String bio,
    required List<String> recentTranscripts,
  }) =>
      _delegate.buildAiTwin(
        userId: userId,
        role: role,
        name: name,
        bio: bio,
        recentTranscripts: recentTranscripts,
      );

  @override
  Future<String> askTwin({
    required AiTwinModel twin,
    required String question,
    List<String> history = const [],
  }) =>
      _delegate.askTwin(twin: twin, question: question, history: history);

  // ── Study assistant shortcut (used by AiTutorViewmodel) ─
  Future<String> askStudyAssistant({
    required String question,
    String? courseTopic,
    List<String> history = const [],
  }) {
    final context = courseTopic != null
        ? 'You are a helpful AI study tutor on the Toriino platform, '
          'assisting with the course topic: "$courseTopic". '
          'Be concise, encouraging, and educational.'
        : 'You are a helpful AI study tutor on the Toriino platform. '
          'Be concise, encouraging, and educational.';
    return _delegate.chat(question, history: [context, ...history]);
  }
}
