import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/error/error_handler.dart';
import 'models/intent_category_response.dart';
import 'models/intent_note_response.dart';
import 'models/note_intent_response.dart';

final intentsRepositoryProvider = Provider<IntentsRepository>((ref) {
  return IntentsRepository(ref.read(apiClientProvider).dio);
});

class IntentsRepository {
  IntentsRepository(this._dio);

  final Dio _dio;

  Future<List<IntentCategoryResponse>> listCategories() async {
    try {
      final response = await _dio.get('/intents/categories');
      return (response.data as List<dynamic>)
          .map((e) =>
              IntentCategoryResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }

  Future<List<IntentNoteResponse>> listNotesForCategory(int categoryId) async {
    try {
      final response =
          await _dio.get('/intents/categories/$categoryId/notes');
      return (response.data as List<dynamic>)
          .map(
              (e) => IntentNoteResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }

  /// Returns null when the note has no intent (404 → silent).
  Future<NoteIntentResponse?> getNoteIntent(int noteId) async {
    try {
      final response = await _dio.get('/intents/notes/$noteId');
      return NoteIntentResponse.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final ex = ErrorHandler.fromDioException(e);
      // 404 means the note has no intent — not an error.
      if (e.response?.statusCode == 404) return null;
      throw ex;
    }
  }
}
