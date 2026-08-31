import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

enum ServerHealth { ok, degraded, unreachable }

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepository(ref.read(apiClientProvider).dio);
});

class HealthRepository {
  HealthRepository(this._dio);

  final Dio _dio;

  Future<ServerHealth> check() async {
    try {
      final response = await _dio.get(
        '/health',
        options: Options(
          // Use a short timeout — health check should be fast.
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      final status = response.data['status'] as String? ?? 'ok';
      return status == 'ok' ? ServerHealth.ok : ServerHealth.degraded;
    } catch (_) {
      return ServerHealth.unreachable;
    }
  }
}
