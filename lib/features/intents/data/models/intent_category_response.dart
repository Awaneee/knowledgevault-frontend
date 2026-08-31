class IntentCategoryResponse {
  const IntentCategoryResponse({
    required this.id,
    required this.name,
    required this.intentType,
    required this.confidence,
    required this.noteCount,
    this.description,
    this.actor,
    this.action,
    this.timeScope,
    this.lastUsedAt,
  });

  final int id;
  final String name;
  final String? description;
  final String intentType;
  final String? actor;
  final String? action;
  final String? timeScope;
  final double confidence;
  final int noteCount;
  final DateTime? lastUsedAt;

  factory IntentCategoryResponse.fromJson(Map<String, dynamic> json) =>
      IntentCategoryResponse(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String?,
        intentType: json['intent_type'] as String,
        actor: json['actor'] as String?,
        action: json['action'] as String?,
        timeScope: json['time_scope'] as String?,
        confidence: (json['confidence'] as num).toDouble(),
        noteCount: json['note_count'] as int,
        lastUsedAt: json['last_used_at'] == null
            ? null
            : DateTime.parse(json['last_used_at'] as String),
      );
}
