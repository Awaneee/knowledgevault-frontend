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

/// Thrown when the server sends an `event: error` frame mid-stream.
class AskStreamException implements Exception {
  const AskStreamException(this.message);

  final String message;

  @override
  String toString() => message;
}

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
  /// Yields answer fragments as they arrive, with whitespace and newlines
  /// preserved so the accumulated text still renders as markdown. The stream
  /// ends on the `[DONE]` sentinel or when the server closes the connection.
  /// No citations are included in the stream.
  Stream<String> streamAsk(String question) async* {
    try {
      final response = await _dio.post(
        '/ask/stream',
        data: AskRequest(question: question).toJson(),
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
          // Retrieval runs before the first token, so the initial gap can be
          // 50–90 s. This is the allowance for that gap, not for the whole
          // answer — each frame that arrives resets it.
          receiveTimeout: const Duration(seconds: 180),
        ),
      );

      final body = response.data as ResponseBody;

      // Decode through a stateful converter: a multi-byte UTF-8 sequence can
      // straddle two network chunks.
      final chunks = body.stream
          .cast<List<int>>()
          .transform(const Utf8Decoder(allowMalformed: true));

      var buffer = '';
      await for (final chunk in chunks) {
        buffer += chunk;

        // Frames are separated by a blank line. Anything after the last
        // separator is a partial frame — keep it buffered.
        var split = _nextFrameBreak(buffer);
        while (split != null) {
          final frame = buffer.substring(0, split.start);
          buffer = buffer.substring(split.end);

          final token = _parseFrame(frame);
          if (token == null) return; // [DONE]
          if (token.isNotEmpty) yield token;

          split = _nextFrameBreak(buffer);
        }
      }

      // Server closed without a trailing blank line — flush what's left.
      final tail = _parseFrame(buffer);
      if (tail != null && tail.isNotEmpty) yield tail;
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }

  /// Locates the next SSE frame separator (`\n\n`, or `\r\n\r\n`).
  ({int start, int end})? _nextFrameBreak(String buffer) {
    final match = RegExp(r'\r?\n\r?\n').firstMatch(buffer);
    return match == null ? null : (start: match.start, end: match.end);
  }

  /// Decodes one SSE frame into its text, or `null` if it ends the stream.
  String? _parseFrame(String frame) {
    if (frame.trim().isEmpty) return '';

    var isError = false;
    final text = StringBuffer();

    for (final line in const LineSplitter().convert(frame)) {
      if (line.startsWith('event:')) {
        isError = line.substring(6).trim() == 'error';
        continue;
      }
      if (!line.startsWith('data:')) continue; // `:` comments, `id:`, `retry:`

      // Per the SSE spec, exactly one space after the colon is separator,
      // not content.
      var payload = line.substring(5);
      if (payload.startsWith(' ')) payload = payload.substring(1);

      if (payload == '[DONE]') return null;
      text.write(_decodePayload(payload));
    }

    if (isError) throw AskStreamException(text.toString());
    return text.toString();
  }

  /// Frames carry JSON-encoded strings so whitespace survives. Older servers
  /// sent bare text, so fall back to using the payload as-is.
  String _decodePayload(String payload) {
    if (payload.isEmpty) return '';
    try {
      final decoded = jsonDecode(payload);
      if (decoded is String) return decoded;
      if (decoded is Map && decoded['token'] is String) {
        return decoded['token'] as String;
      }
    } on FormatException {
      // Not JSON — treat it as a raw text token.
    }
    return payload;
  }
}
