import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/error/error_handler.dart';
import '../../notes/data/models/note_search_response.dart';
import 'models/chunk_result.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(ref.read(apiClientProvider).dio);
});

class SearchRepository {
  SearchRepository(this._dio);

  final Dio _dio;

  /// Note-level semantic search — GET /notes/search
  Future<List<NoteSearchResponse>> searchNotes(
    String query, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        '/notes/search',
        queryParameters: {'q': query},
        cancelToken: cancelToken,
      );
      return (response.data as List<dynamic>)
          .map((e) => NoteSearchResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return [];
      throw ErrorHandler.fromDioException(e);
    }
  }

  /// Chunk-level semantic retrieval — POST /retrieve
  Future<List<ChunkResult>> retrieve(
    String query, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        '/retrieve',
        data: {'query': query},
        cancelToken: cancelToken,
      );
      return (response.data as List<dynamic>)
          .map((e) => ChunkResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return [];
      throw ErrorHandler.fromDioException(e);
    }
  }

  /// Intent-aware hybrid retrieval — POST /retrieve/hybrid
  Future<List<ChunkResult>> retrieveHybrid(
    String query, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        '/retrieve/hybrid',
        data: {'query': query},
        cancelToken: cancelToken,
      );
      return (response.data as List<dynamic>)
          .map((e) => ChunkResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return [];
      throw ErrorHandler.fromDioException(e);
    }
  }
}
