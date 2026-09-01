import 'package:toriino_todd/model/ai/session_summary_model.dart';
import 'package:toriino_todd/model/ai/transcript_model.dart';
import 'package:toriino_todd/services/gemini_service.dart';

/// Orchestrates the session intelligence pipeline:
/// 1. Accumulates transcript segments during a live Agora session.
/// 2. On session end, posts transcript to the backend for storage.
/// 3. Calls Gemini to generate summary, action items, and insights.
///
/// Transcription note: full automatic transcription requires a server-side
/// Agora Cloud Recording + speech-to-text pipeline (e.g. AWS Transcribe or
/// Google Speech-to-Text). The Flutter side accumulates manually-added
/// segments and can be extended once that pipeline is wired up.
class SessionIntelligenceService {
  final String sessionId;
  final String subjectArea;

  final List<TranscriptSegment> _segments = [];
  DateTime? _startTime;

  SessionIntelligenceService({
    required this.sessionId,
    required this.subjectArea,
  });

  // ── Called when the session starts ──────────────────────
  void onSessionStart() {
    _startTime = DateTime.now();
    _segments.clear();
  }

  // ── Add a transcript segment (from STT callback or manual caption) ─
  void addSegment({
    required String speakerId,
    required String speakerName,
    required String text,
  }) {
    if (text.trim().isEmpty) return;
    final elapsed = _startTime != null
        ? DateTime.now().difference(_startTime!)
        : Duration.zero;
    _segments.add(TranscriptSegment(
      speakerId: speakerId,
      speakerName: speakerName,
      text: text.trim(),
      timestamp: elapsed,
    ));
  }

  // ── Called when the session ends ─────────────────────────
  /// Returns the full transcript model. Call [generateSummary] after this.
  TranscriptModel onSessionEnd() {
    final duration = _startTime != null
        ? DateTime.now().difference(_startTime!)
        : Duration.zero;
    return TranscriptModel(
      sessionId: sessionId,
      segments: List.unmodifiable(_segments),
      recordedAt: _startTime ?? DateTime.now(),
      totalDuration: duration,
    );
  }

  // ── Generate AI summary from the accumulated transcript ──
  Future<SessionSummaryModel> generateSummary() async {
    if (_segments.isEmpty) {
      return SessionSummaryModel(
        sessionId: sessionId,
        summary: 'No transcript available for this session.',
        actionItems: [],
        keyTopics: [],
        insights: [],
        generatedAt: DateTime.now(),
      );
    }

    final transcript = TranscriptModel(
      sessionId: sessionId,
      segments: _segments,
      recordedAt: _startTime ?? DateTime.now(),
      totalDuration: _startTime != null
          ? DateTime.now().difference(_startTime!)
          : Duration.zero,
    );

    return GeminiService.instance.summarizeSession(
      sessionId: sessionId,
      transcript: transcript.toPlainText(),
      subjectArea: subjectArea,
    );
  }

  // ── Convenience: segment count ───────────────────────────
  int get segmentCount => _segments.length;

  bool get hasTranscript => _segments.isNotEmpty;
}
