class ChunkPreview {
  const ChunkPreview({
    required this.title,
    required this.preview,
    required this.score,
    this.category,
  });

  final String title;
  final String preview;
  final double score;
  final String? category;

  factory ChunkPreview.fromJson(Map<String, dynamic> json) => ChunkPreview(
        title: json['title'] as String,
        preview: json['preview'] as String,
        score: (json['score'] as num).toDouble(),
        category: json['category'] as String?,
      );
}
