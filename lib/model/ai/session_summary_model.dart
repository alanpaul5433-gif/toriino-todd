class SessionSummaryModel {
  final String sessionId;
  final String summary;
  final List<String> actionItems;
  final List<String> keyTopics;
  final List<String> insights;
  final String? transcript;
  final DateTime generatedAt;

  SessionSummaryModel({
    required this.sessionId,
    required this.summary,
    required this.actionItems,
    required this.keyTopics,
    required this.insights,
    this.transcript,
    required this.generatedAt,
  });

  factory SessionSummaryModel.fromJson(Map<String, dynamic> json) {
    return SessionSummaryModel(
      sessionId: json['sessionId'] ?? '',
      summary: json['summary'] ?? '',
      actionItems: List<String>.from(json['actionItems'] ?? []),
      keyTopics: List<String>.from(json['keyTopics'] ?? []),
      insights: List<String>.from(json['insights'] ?? []),
      transcript: json['transcript'],
      generatedAt:
          DateTime.tryParse(json['generatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'summary': summary,
        'actionItems': actionItems,
        'keyTopics': keyTopics,
        'insights': insights,
        if (transcript != null) 'transcript': transcript,
        'generatedAt': generatedAt.toIso8601String(),
      };
}
