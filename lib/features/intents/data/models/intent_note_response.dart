class IntentNoteResponse {
  const IntentNoteResponse({
    required this.id,
    required this.title,
    required this.createdAt,
    this.content,
  });

  final int id;
  final String title;
  final String? content;
  final DateTime createdAt;

  factory IntentNoteResponse.fromJson(Map<String, dynamic> json) =>
      IntentNoteResponse(
        id: json['id'] as int,
        title: json['title'] as String,
        content: json['content'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
