import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:toriino_todd/config/app_config.dart';
import 'package:toriino_todd/model/ai/ai_twin_model.dart';
import 'package:toriino_todd/model/ai/session_summary_model.dart';
import 'package:toriino_todd/services/ai_interface.dart';

class GeminiService implements AiInterface {
  static const _modelName = 'gemini-flash-latest';

  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: _modelName,
      apiKey: AppConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 2048,
      ),
    );
  }

  // ── Singleton ────────────────────────────────────────
  static GeminiService? _instance;
  static GeminiService get instance => _instance ??= GeminiService();

  // ── Core generation ──────────────────────────────────
  Future<String> _generate(String prompt) async {
    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text ?? '';
  }

  // ── AiInterface implementation ───────────────────────

  @override
  Future<String> ask(String question, {String? context}) async {
    final prompt = context != null
        ? 'Context: $context\n\nQuestion: $question'
        : question;
    return _generate(prompt);
  }

  @override
  Future<String> chat(String message, {List<String> history = const []}) async {
    final historyContent = <Content>[];
    for (int i = 0; i < history.length; i++) {
      historyContent.add(
        i.isEven ? Content.text(history[i]) : Content('model', [TextPart(history[i])]),
      );
    }
    final session = _model.startChat(history: historyContent);
    final response = await session.sendMessage(Content.text(message));
    return response.text ?? '';
  }

  @override
  Future<SessionSummaryModel> summarizeSession({
    required String sessionId,
    required String transcript,
    String? subjectArea,
  }) async {
    final subject = subjectArea != null ? ' for "$subjectArea"' : '';
    final prompt = '''
You are an expert educational analyst. Analyze this live session transcript$subject and return a JSON object with exactly these keys:
- "summary": 2-3 sentence overview of what was covered
- "actionItems": array of strings (tasks/homework for the student)
- "keyTopics": array of strings (main subjects discussed)
- "insights": array of strings (notable teaching moments or learner breakthroughs)

Transcript:
$transcript

Respond ONLY with valid JSON. No markdown, no explanation.
''';

    final raw = await _generate(prompt);
    try {
      final cleaned = raw.replaceAll('```json', '').replaceAll('```', '').trim();
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      return SessionSummaryModel(
        sessionId: sessionId,
        summary: json['summary'] ?? '',
        actionItems: List<String>.from(json['actionItems'] ?? []),
        keyTopics: List<String>.from(json['keyTopics'] ?? []),
        insights: List<String>.from(json['insights'] ?? []),
        transcript: transcript,
        generatedAt: DateTime.now(),
      );
    } catch (_) {
      // Fallback: treat entire response as summary
      return SessionSummaryModel(
        sessionId: sessionId,
        summary: raw,
        actionItems: [],
        keyTopics: [],
        insights: [],
        transcript: transcript,
        generatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<String> generateCourseOutline(String topic, {int numModules = 6}) {
    return _generate(
      'Create a structured course outline for: "$topic".\n'
      'Include $numModules modules with a title and 3-4 lesson ideas each.\n'
      'Format as a numbered list.',
    );
  }

  @override
  Future<String> summarizeReviews(List<String> reviews) {
    if (reviews.isEmpty) return Future.value('No reviews yet.');
    final joined = reviews.map((r) => '- $r').join('\n');
    return _generate(
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
    final transcriptSample = recentTranscripts.take(3).join('\n\n---\n\n');
    final prompt = '''
Analyze this educator's bio and recent session transcripts to build their AI Twin profile.
Return a JSON object with:
- "personalityProfile": 2-3 sentence description of their teaching personality
- "expertiseAreas": array of subject expertise strings
- "teachingStyle": array of pedagogical style descriptors (e.g. "Socratic", "example-driven")

Name: $name
Role: $role
Bio: $bio

Recent Session Transcripts:
$transcriptSample

Respond ONLY with valid JSON.
''';

    final raw = await _generate(prompt);
    try {
      final cleaned = raw.replaceAll('```json', '').replaceAll('```', '').trim();
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
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
    } catch (_) {
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
  }

  @override
  Future<String> askTwin({
    required AiTwinModel twin,
    required String question,
    List<String> history = const [],
  }) async {
    return chat(question, history: [twin.toSystemPrompt(), ...history]);
  }

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
    return chat(question, history: [context, ...history]);
  }
}
