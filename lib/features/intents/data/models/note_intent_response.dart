class NoteIntentResponse {
  const NoteIntentResponse({
    required this.id,
    required this.noteId,
    required this.intentType,
    required this.confidence,
    required this.modelName,
    this.action,
    this.actor,
    this.topic,
    this.subtopic,
    this.object,
    this.dueDate,
    this.temporalText,
    this.urgency,
  });

  final int id;
  final int noteId;
  final String intentType;
  final String? action;
  final String? actor;
  final String? topic;
  final String? subtopic;
  final String? object;
  final DateTime? dueDate;
  final String? temporalText;
  final String? urgency;
  final double confidence;
  final String modelName;

  factory NoteIntentResponse.fromJson(Map<String, dynamic> json) =>
      NoteIntentResponse(
        id: json['id'] as int,
        noteId: json['note_id'] as int,
        intentType: json['intent_type'] as String,
        action: json['action'] as String?,
        actor: json['actor'] as String?,
        topic: json['topic'] as String?,
        subtopic: json['subtopic'] as String?,
        object: json['object'] as String?,
        dueDate: json['due_date'] == null
            ? null
            : DateTime.parse(json['due_date'] as String),
        temporalText: json['temporal_text'] as String?,
        urgency: json['urgency'] as String?,
        confidence: (json['confidence'] as num).toDouble(),
        modelName: json['model_name'] as String,
      );
}
