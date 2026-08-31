import '../../../intents/data/models/intent_category_response.dart';
import '../../../intents/data/models/note_intent_response.dart';

class NoteCreateResponse {
  const NoteCreateResponse({
    required this.id,
    required this.title,
    required this.userId,
    required this.createdAt,
    this.content,
    this.categoryId,
    this.autoTitleSource,
    this.organizationStatus,
    this.intent,
    this.intentCategory,
  });

  final int id;
  final String title;
  final String? content;
  final int userId;
  final int? categoryId;
  final String? autoTitleSource;
  final String? organizationStatus;
  final DateTime createdAt;
  final NoteIntentResponse? intent;
  final IntentCategoryResponse? intentCategory;

  factory NoteCreateResponse.fromJson(Map<String, dynamic> json) =>
      NoteCreateResponse(
        id: json['id'] as int,
        title: json['title'] as String,
        content: json['content'] as String?,
        userId: json['user_id'] as int,
        categoryId: json['category_id'] as int?,
        autoTitleSource: json['auto_title_source'] as String?,
        organizationStatus: json['organization_status'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        intent: json['intent'] == null
            ? null
            : NoteIntentResponse.fromJson(
                json['intent'] as Map<String, dynamic>),
        intentCategory: json['intent_category'] == null
            ? null
            : IntentCategoryResponse.fromJson(
                json['intent_category'] as Map<String, dynamic>),
      );
}
