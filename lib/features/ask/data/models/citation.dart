class Citation {
  const Citation({
    required this.ref,
    required this.noteId,
    required this.noteTitle,
    required this.snippet,
    this.chunkId,
  });

  final int ref;
  final int noteId;
  final String noteTitle;
  final int? chunkId;
  final String snippet;

  factory Citation.fromJson(Map<String, dynamic> json) => Citation(
        ref: json['ref'] as int,
        noteId: json['note_id'] as int,
        noteTitle: json['note_title'] as String,
        chunkId: json['chunk_id'] as int?,
        snippet: json['snippet'] as String,
      );
}
