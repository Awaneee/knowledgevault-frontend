import 'citation.dart';
import 'chunk_preview.dart';

class AskResponse {
  const AskResponse({
    required this.question,
    required this.answer,
    required this.sources,
    required this.citations,
    required this.retrievalOnly,
    required this.status,
    required this.reranked,
    required this.chunks,
    this.provider,
  });

  final String question;
  final String answer;
  final List<String> sources;
  final List<Citation> citations;
  final bool retrievalOnly;
  final String status;
  final String? provider;
  final bool reranked;
  final List<ChunkPreview> chunks;

  bool get isDegraded => retrievalOnly || status == 'degraded';

  factory AskResponse.fromJson(Map<String, dynamic> json) => AskResponse(
        question: json['question'] as String,
        answer: json['answer'] as String,
        sources: (json['sources'] as List<dynamic>).cast<String>(),
        citations: (json['citations'] as List<dynamic>)
            .map((e) => Citation.fromJson(e as Map<String, dynamic>))
            .toList(),
        retrievalOnly: json['retrieval_only'] as bool? ?? false,
        status: json['status'] as String? ?? 'ok',
        provider: json['provider'] as String?,
        reranked: json['reranked'] as bool? ?? false,
        chunks: (json['chunks'] as List<dynamic>? ?? [])
            .map((e) => ChunkPreview.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
