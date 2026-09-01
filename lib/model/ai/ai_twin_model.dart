class AiTwinModel {
  final String userId;
  final String role; // Teacher | Mentor | Coach
  final String name;
  final String personalityProfile;
  final List<String> expertiseAreas;
  final List<String> teachingStyle;
  final Map<String, dynamic> knowledgeMemory;
  final DateTime lastUpdated;

  AiTwinModel({
    required this.userId,
    required this.role,
    required this.name,
    required this.personalityProfile,
    required this.expertiseAreas,
    required this.teachingStyle,
    required this.knowledgeMemory,
    required this.lastUpdated,
  });

  factory AiTwinModel.fromJson(Map<String, dynamic> json) {
    return AiTwinModel(
      userId: json['userId'] ?? '',
      role: json['role'] ?? '',
      name: json['name'] ?? '',
      personalityProfile: json['personalityProfile'] ?? '',
      expertiseAreas: List<String>.from(json['expertiseAreas'] ?? []),
      teachingStyle: List<String>.from(json['teachingStyle'] ?? []),
      knowledgeMemory: Map<String, dynamic>.from(json['knowledgeMemory'] ?? {}),
      lastUpdated:
          DateTime.tryParse(json['lastUpdated'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'role': role,
        'name': name,
        'personalityProfile': personalityProfile,
        'expertiseAreas': expertiseAreas,
        'teachingStyle': teachingStyle,
        'knowledgeMemory': knowledgeMemory,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  String toSystemPrompt() {
    return '''You are ${name}'s AI Twin on the Toriino platform.
Role: $role
Expertise: ${expertiseAreas.join(', ')}
Teaching Style: ${teachingStyle.join(', ')}
Personality: $personalityProfile

You speak in ${name}'s voice and draw on their teaching experience.
Be helpful, encouraging, and accurate. Never fabricate information.''';
  }
}
