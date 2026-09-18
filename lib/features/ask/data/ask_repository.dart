import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/error/error_handler.dart';
import 'models/ask_request.dart';
import 'models/ask_response.dart';
import 'models/citation.dart';

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

/// One decoded item from the `/ask/stream` SSE stream.
sealed class AskStreamEvent {
  const AskStreamEvent();
}

/// A fragment of answer text, whitespace preserved.
class AskToken extends AskStreamEvent {
  const AskToken(this.text);
  final String text;
}

/// The resolved citations, sent once after the last token.
class AskCitations extends AskStreamEvent {
  const AskCitations(this.citations);
  final List<Citation> citations;
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
  /// Yields [AskToken]s as the answer arrives, with whitespace and newlines
  /// preserved so the accumulated text still renders as markdown, then one
  /// [AskCitations] after the last token if the answer cited any notes. The
  /// stream ends on the `[DONE]` sentinel or when the server closes the
  /// connection.
  Stream<AskStreamEvent> streamAsk(String question) async* {
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

          final event = parseFrame(frame);
          if (event == null) return; // [DONE]
          if (!(event is AskToken && event.text.isEmpty)) yield event;

          split = _nextFrameBreak(buffer);
        }
      }

      // Server closed without a trailing blank line — flush what's left.
      final tail = parseFrame(buffer);
      if (tail != null && !(tail is AskToken && tail.text.isEmpty)) yield tail;
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }

  /// Locates the next SSE frame separator (`\n\n`, or `\r\n\r\n`).
  ({int start, int end})? _nextFrameBreak(String buffer) {
    final match = RegExp(r'\r?\n\r?\n').firstMatch(buffer);
    return match == null ? null : (start: match.start, end: match.end);
  }

  /// Decodes one SSE frame, or returns `null` if it ends the stream.
  @visibleForTesting
  AskStreamEvent? parseFrame(String frame) {
    if (frame.trim().isEmpty) return const AskToken('');

    String? event;
    final text = StringBuffer();

    for (final line in const LineSplitter().convert(frame)) {
      if (line.startsWith('event:')) {
        event = line.substring(6).trim();
        continue;
      }
      if (!line.startsWith('data:')) continue; // `:` comments, `id:`, `retry:`

      // Per the SSE spec, exactly one space after the colon is separator,
      // not content.
      var payload = line.substring(5);
      if (payload.startsWith(' ')) payload = payload.substring(1);

      if (payload == '[DONE]') return null;
      text.write(event == 'citations' ? payload : _decodePayload(payload));
    }

    if (event == 'error') throw AskStreamException(text.toString());
    if (event == 'citations') return AskCitations(_decodeCitations(text.toString()));
    return AskToken(text.toString());
  }

  List<Citation> _decodeCitations(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is List) {
        return [
          for (final c in decoded)
            if (c is Map<String, dynamic>) Citation.fromJson(c),
        ];
      }
    } on FormatException {
      // Malformed citations must never break an otherwise good answer.
    } on TypeError {
      // Same: a field with an unexpected type.
    }
    return const [];
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
