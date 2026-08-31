class NoteSearchResponse {
  const NoteSearchResponse({
    required this.id,
    required this.title,
    this.content,
  });

  final int id;
  final String title;
  final String? content;

  factory NoteSearchResponse.fromJson(Map<String, dynamic> json) =>
      NoteSearchResponse(
        id: json['id'] as int,
        title: json['title'] as String,
        content: json['content'] as String?,
      );
}
