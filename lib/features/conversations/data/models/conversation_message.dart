class ConversationMessage {
  final int id;
  final String role; // "user" | "assistant"
  final String content;
  final List<dynamic>? citations;
  final DateTime createdAt;

  const ConversationMessage({
    required this.id,
    required this.role,
    required this.content,
    this.citations,
    required this.createdAt,
  });

  factory ConversationMessage.fromJson(Map<String, dynamic> j) =>
      ConversationMessage(
        id: j['id'] as int,
        role: j['role'] as String,
        content: j['content'] as String,
        citations: j['citations'] as List<dynamic>?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}
