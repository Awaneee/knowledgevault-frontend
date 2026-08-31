import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'auth_interceptor.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(authInterceptor: ref.read(authInterceptorProvider));
});

class ApiClient {
  ApiClient({required AuthInterceptor authInterceptor}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.addAll([
      authInterceptor,
      if (kDebugMode)
        LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }

  late final Dio _dio;

  Dio get dio => _dio;
}
