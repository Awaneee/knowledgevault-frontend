class TopicNoteItem {
  const TopicNoteItem({required this.id, required this.title});

  final int id;
  final String title;

  factory TopicNoteItem.fromJson(Map<String, dynamic> json) => TopicNoteItem(
        id: json['id'] as int,
        title: json['title'] as String,
      );
}

class TopicResponse {
  const TopicResponse({
    required this.clusterId,
    required this.topicName,
    required this.notes,
  });

  final int clusterId;
  final String topicName;
  final List<TopicNoteItem> notes;

  factory TopicResponse.fromJson(Map<String, dynamic> json) => TopicResponse(
        clusterId: json['cluster_id'] as int,
        topicName: json['topic_name'] as String,
        notes: (json['notes'] as List<dynamic>)
            .map((e) => TopicNoteItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
