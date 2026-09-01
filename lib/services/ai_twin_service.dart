import 'package:toriino_todd/model/ai/ai_twin_model.dart';
import 'package:toriino_todd/repository/ai_repo.dart';
import 'package:toriino_todd/services/gemini_service.dart';

/// Manages AI Twin lifecycle: creation, updates, and querying.
/// An AI Twin is a personalized AI persona built from a teacher's,
/// mentor's, or coach's bio, teaching style, and session history.
class AiTwinService {
  static final AiTwinService instance = AiTwinService._();
  AiTwinService._();

  AiTwinModel? _cachedTwin;

  // ── Load a twin from the backend (cache locally) ─────────
  Future<AiTwinModel?> loadTwin(String userId) async {
    if (_cachedTwin?.userId == userId) return _cachedTwin;
    _cachedTwin = await AiRepo.getTwin(userId);
    return _cachedTwin;
  }

  // ── Build/rebuild a twin from bio + recent transcripts ───
  Future<AiTwinModel> buildTwin({
    required String userId,
    required String role,
    required String name,
    required String bio,
    required List<String> recentTranscripts,
  }) async {
    final twin = await GeminiService.instance.buildAiTwin(
      userId: userId,
      role: role,
      name: name,
      bio: bio,
      recentTranscripts: recentTranscripts,
    );
    await AiRepo.saveTwin(twin);
    _cachedTwin = twin;
    return twin;
  }

  // ── Ask a twin a question ─────────────────────────────────
  Future<String> ask({
    required String userId,
    required String question,
    List<String> conversationHistory = const [],
  }) async {
    final twin = await loadTwin(userId);
    if (twin == null) {
      return 'This expert’s AI Twin is not available yet.';
    }
    return GeminiService.instance.askTwin(
      twin: twin,
      question: question,
      history: conversationHistory,
    );
  }

  void clearCache() => _cachedTwin = null;
}
