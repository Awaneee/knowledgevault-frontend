import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_state.dart';
import '../auth/token_storage.dart';

final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  return AuthInterceptor(
    tokenStorage: ref.read(tokenStorageProvider),
    onUnauthenticated: ({required bool expired}) {
      if (expired) {
        ref.read(sessionExpiredProvider.notifier).state = true;
      }
      ref.read(authStatusProvider.notifier).setUnauthenticated();
    },
  );
});

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.tokenStorage,
    required this.onUnauthenticated,
  });

  final TokenStorage tokenStorage;
  final void Function({required bool expired}) onUnauthenticated;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenStorage.read();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await tokenStorage.delete();
      // expired = true only when a token WAS present (real session expiry,
      // not a login attempt with wrong credentials).
      final hadToken = err.requestOptions.headers['Authorization'] != null;
      onUnauthenticated(expired: hadToken);
    }
    handler.next(err);
  }
}
