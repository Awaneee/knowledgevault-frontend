import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/error/error_handler.dart';
import 'models/ask_request.dart';
import 'models/ask_response.dart';

final askRepositoryProvider = Provider<AskRepository>((ref) {
  return AskRepository(ref.read(apiClientProvider).dio);
});

class AskRepository {
  AskRepository(this._dio);

  final Dio _dio;

  /// Full response with citations — POST /ask/
  Future<AskResponse> ask(String question) async {
    try {
      final response = await _dio.post(
        '/ask/',
        data: AskRequest(question: question).toJson(),
        options: Options(receiveTimeout: const Duration(seconds: 120)),
      );
      return AskResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }

  /// SSE streaming response — POST /ask/stream
  ///
  /// Yields plain text tokens as they arrive. The stream ends when the server
  /// closes the connection. No citations are included in the stream.
  Stream<String> streamAsk(String question) async* {
    try {
      final response = await _dio.post(
        '/ask/stream',
        data: AskRequest(question: question).toJson(),
        // LLM generation can take 50–90 s before the first token arrives.
        // Disable the per-response receive timeout for this endpoint only.
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

      final body = response.data as ResponseBody;

      await for (final bytes in body.stream) {
        final raw = utf8.decode(bytes, allowMalformed: true);
        for (final line in const LineSplitter().convert(raw)) {
          if (line.isEmpty) continue;
          // Support both SSE format ("data: token") and raw token chunks.
          final token = line.startsWith('data:')
              ? line.substring(5).trim()
              : line.trim();
          if (token.isEmpty || token == '[DONE]') continue;
          yield token;
        }
      }
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }
}
