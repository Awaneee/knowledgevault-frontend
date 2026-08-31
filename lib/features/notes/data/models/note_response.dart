class NoteResponse {
  const NoteResponse({
    required this.id,
    required this.title,
    required this.userId,
    required this.createdAt,
    this.content,
    this.categoryId,
    this.autoTitleSource,
    this.organizationStatus,
  });

  final int id;
  final String title;
  final String? content;
  final int userId;
  final int? categoryId;
  final String? autoTitleSource;
  final String? organizationStatus;
  final DateTime createdAt;

  factory NoteResponse.fromJson(Map<String, dynamic> json) => NoteResponse(
        id: json['id'] as int,
        title: json['title'] as String,
        content: json['content'] as String?,
        userId: json['user_id'] as int,
        categoryId: json['category_id'] as int?,
        autoTitleSource: json['auto_title_source'] as String?,
        organizationStatus: json['organization_status'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
