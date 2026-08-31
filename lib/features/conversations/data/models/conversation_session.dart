class ConversationSession {
  final int id;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;

  const ConversationSession({
    required this.id,
    this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
  });

  factory ConversationSession.fromJson(Map<String, dynamic> j) =>
      ConversationSession(
        id: j['id'] as int,
        title: j['title'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
        messageCount: j['message_count'] as int? ?? 0,
      );
}
