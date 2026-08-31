import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/error/error_handler.dart';

final backfillRepositoryProvider = Provider<BackfillRepository>((ref) {
  return BackfillRepository(ref.read(apiClientProvider).dio);
});

class BackfillResult {
  const BackfillResult({
    required this.processed,
    required this.failed,
    required this.remainingHint,
  });

  final int processed;
  final int failed;
  final int remainingHint;

  factory BackfillResult.fromJson(Map<String, dynamic> json) => BackfillResult(
        processed: json['processed'] as int,
        failed: json['failed'] as int,
        remainingHint: json['remaining_hint'] as int,
      );
}

class BackfillRepository {
  BackfillRepository(this._dio);

  final Dio _dio;

  Future<BackfillResult> run({int limit = 50}) async {
    try {
      final response = await _dio.post(
        '/intents/backfill',
        queryParameters: {'limit': limit},
        // Backfill can run up to 60 seconds on the server.
        options: Options(receiveTimeout: const Duration(seconds: 90)),
      );
      return BackfillResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }
}
