import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/error/error_handler.dart';
import 'models/note_create_request.dart';
import 'models/note_create_response.dart';
import 'models/note_response.dart';
import 'models/note_search_response.dart';
import 'models/related_note_response.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository(ref.read(apiClientProvider).dio);
});

class NotesRepository {
  NotesRepository(this._dio);

  final Dio _dio;

  Future<List<NoteResponse>> listNotes() async {
    try {
      final response = await _dio.get('/notes/');
      return (response.data as List<dynamic>)
          .map((e) => NoteResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }

  Future<NoteCreateResponse> createNote(String content) async {
    try {
      final response = await _dio.post(
        '/notes/',
        data: NoteCreateRequest(content: content).toJson(),
      );
      return NoteCreateResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }

  Future<NoteResponse> getNote(int id) async {
    try {
      final response = await _dio.get('/notes/$id');
      return NoteResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }

  Future<NoteResponse> updateCategory(int id, int? categoryId) async {
    try {
      final response = await _dio.patch(
        '/notes/$id/category',
        data: {'category_id': categoryId},
      );
      return NoteResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      await _dio.delete('/notes/$id');
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }

  Future<List<NoteSearchResponse>> searchNotes(String query) async {
    try {
      final response = await _dio.get(
        '/notes/search',
        queryParameters: {'q': query},
      );
      return (response.data as List<dynamic>)
          .map((e) => NoteSearchResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }

  Future<List<RelatedNoteResponse>> getRelatedNotes(int noteId) async {
    try {
      final response = await _dio.get('/notes/$noteId/related');
      return (response.data as List<dynamic>)
          .map((e) => RelatedNoteResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }

  /// Uploads a file and creates a note from its content.
  /// Returns the ID of the created note.
  Future<int> uploadFile(String filePath, String filename) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: filename),
      });
      final response = await _dio.post('/uploads/file', data: formData);
      return response.data['note_id'] as int;
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }
}
