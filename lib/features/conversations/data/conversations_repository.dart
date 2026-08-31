import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/error/error_handler.dart';
import 'models/conversation_detail.dart';
import 'models/conversation_session.dart';

final conversationsRepositoryProvider = Provider<ConversationsRepository>((ref) {
  return ConversationsRepository(ref.read(apiClientProvider).dio);
});

class ConversationsRepository {
  ConversationsRepository(this._dio);

  final Dio _dio;

  Future<List<ConversationSession>> listSessions() async {
    try {
      final response = await _dio.get('/conversations/');
      return (response.data as List<dynamic>)
          .map((e) => ConversationSession.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }

  Future<ConversationDetail> getSession(int id) async {
    try {
      final response = await _dio.get('/conversations/$id');
      return ConversationDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }

  Future<ConversationSession> createSession() async {
    try {
      final response = await _dio.post('/conversations/');
      return ConversationSession.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }

  Future<void> deleteSession(int id) async {
    try {
      await _dio.delete('/conversations/$id');
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> askInSession(
      int sessionId, String question) async {
    try {
      final response = await _dio.post(
        '/conversations/$sessionId/ask',
        data: {'question': question},
        options: Options(receiveTimeout: const Duration(seconds: 120)),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }
}
