class RelatedNoteResponse {
  final int noteId;
  final String title;
  final String snippet;
  final double similarity;

  const RelatedNoteResponse({
    required this.noteId,
    required this.title,
    required this.snippet,
    required this.similarity,
  });

  factory RelatedNoteResponse.fromJson(Map<String, dynamic> j) =>
      RelatedNoteResponse(
        noteId: j['note_id'] as int,
        title: j['title'] as String,
        snippet: j['snippet'] as String? ?? '',
        similarity: (j['similarity'] as num).toDouble(),
      );
}
