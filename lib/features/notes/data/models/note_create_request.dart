class NoteCreateRequest {
  const NoteCreateRequest({required this.content});

  final String content;

  Map<String, dynamic> toJson() => {'content': content};
}
