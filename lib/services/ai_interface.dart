import 'package:toriino_todd/model/ai/ai_twin_model.dart';
import 'package:toriino_todd/model/ai/session_summary_model.dart';

/// Model-agnostic AI interface. Swap Gemini for any LLM without
/// touching any viewmodel or repository.
abstract class AiInterface {
  /// Send a single question with optional context. Returns the AI's reply.
  Future<String> ask(String question, {String? context});

  /// Continue a multi-turn conversation. [history] is alternating
  /// [user, ai, user, ai, ...] strings.
  Future<String> chat(String message, {List<String> history = const []});

  /// Summarize a session transcript into structured insights.
  Future<SessionSummaryModel> summarizeSession({
    required String sessionId,
    required String transcript,
    String? subjectArea,
  });

  /// Generate a course outline for a given topic.
  Future<String> generateCourseOutline(String topic, {int numModules = 6});

  /// Summarize a list of student reviews.
  Future<String> summarizeReviews(List<String> reviews);

  /// Build or update an AI Twin profile from session transcripts and
  /// user-provided bio.
  Future<AiTwinModel> buildAiTwin({
    required String userId,
    required String role,
    required String name,
    required String bio,
    required List<String> recentTranscripts,
  });

  /// Ask an AI Twin a question. The twin answers in the expert's persona.
  Future<String> askTwin({
    required AiTwinModel twin,
    required String question,
    List<String> history = const [],
  });
}
