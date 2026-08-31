import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notes/data/models/note_search_response.dart';
import '../data/models/chunk_result.dart';
import '../data/search_repository.dart';

// ── Smart search (note-level) ─────────────────────────────────────────────────

final smartSearchProvider = FutureProvider.autoDispose
    .family<List<NoteSearchResponse>, String>((ref, query) async {
  if (query.trim().isEmpty) return const [];
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  return ref
      .read(searchRepositoryProvider)
      .searchNotes(query, cancelToken: cancelToken);
});

// ── Semantic search (chunk-level) ─────────────────────────────────────────────

final semanticSearchProvider = FutureProvider.autoDispose
    .family<List<ChunkResult>, String>((ref, query) async {
  if (query.trim().isEmpty) return const [];
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  return ref
      .read(searchRepositoryProvider)
      .retrieve(query, cancelToken: cancelToken);
});

// ── Hybrid search (intent-aware) ──────────────────────────────────────────────

final hybridSearchProvider = FutureProvider.autoDispose
    .family<List<ChunkResult>, String>((ref, query) async {
  if (query.trim().isEmpty) return const [];
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  return ref
      .read(searchRepositoryProvider)
      .retrieveHybrid(query, cancelToken: cancelToken);
});
