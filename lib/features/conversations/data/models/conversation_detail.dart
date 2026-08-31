import 'conversation_message.dart';
import 'conversation_session.dart';

class ConversationDetail {
  final int id;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final List<ConversationMessage> messages;

  const ConversationDetail({
    required this.id,
    this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
    required this.messages,
  });

  factory ConversationDetail.fromJson(Map<String, dynamic> j) =>
      ConversationDetail(
        id: j['id'] as int,
        title: j['title'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
        messageCount: j['message_count'] as int? ?? 0,
        messages: (j['messages'] as List<dynamic>? ?? [])
            .map((m) => ConversationMessage.fromJson(m as Map<String, dynamic>))
            .toList(),
      );

  ConversationSession get session => ConversationSession(
        id: id,
        title: title,
        createdAt: createdAt,
        updatedAt: updatedAt,
        messageCount: messageCount,
      );
}
