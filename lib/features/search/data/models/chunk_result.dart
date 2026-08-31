class ChunkResult {
  const ChunkResult({
    required this.chunkText,
    required this.noteTitle,
    this.source,
    this.intentCategory,
  });

  final String chunkText;
  final String noteTitle;
  final String? source;
  final String? intentCategory;

  factory ChunkResult.fromJson(Map<String, dynamic> json) => ChunkResult(
        chunkText: json['chunk_text'] as String,
        noteTitle: json['note_title'] as String,
        source: json['source'] as String?,
        intentCategory: json['intent_category'] as String?,
      );
}
