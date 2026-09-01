class TranscriptSegment {
  final String speakerId;
  final String speakerName;
  final String text;
  final Duration timestamp;

  TranscriptSegment({
    required this.speakerId,
    required this.speakerName,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'speakerId': speakerId,
        'speakerName': speakerName,
        'text': text,
        'timestampSeconds': timestamp.inSeconds,
      };
}

class TranscriptModel {
  final String sessionId;
  final List<TranscriptSegment> segments;
  final DateTime recordedAt;
  final Duration totalDuration;

  TranscriptModel({
    required this.sessionId,
    required this.segments,
    required this.recordedAt,
    required this.totalDuration,
  });

  String toPlainText() {
    return segments
        .map((s) => '[${s.speakerName}]: ${s.text}')
        .join('\n');
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'segments': segments.map((s) => s.toJson()).toList(),
        'recordedAt': recordedAt.toIso8601String(),
        'totalDurationSeconds': totalDuration.inSeconds,
      };
}
