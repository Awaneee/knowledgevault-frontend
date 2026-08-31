import 'package:dio/dio.dart';

import '../api/api_exceptions.dart';

abstract final class ErrorHandler {
  static ApiException fromDioException(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException();
    }

    final status = e.response?.statusCode;
    final detail = e.response?.data is Map<String, dynamic>
        ? (e.response!.data as Map<String, dynamic>)['detail']?.toString()
        : null;

    return switch (status) {
      400 => ConflictException(detail ?? 'Bad request'),
      401 => UnauthorizedException(detail ?? 'Unauthorized'),
      403 => ForbiddenException(detail ?? 'Access forbidden'),
      404 => NotFoundException(detail ?? 'Not found'),
      422 => ValidationException(detail ?? 'Validation error'),
      429 => const RateLimitException(),
      _ => ServerException(detail ?? 'An unexpected error occurred'),
    };
  }

  static String toUserMessage(Object error) {
    if (error is ApiException) return error.message;
    return 'An unexpected error occurred';
  }
}
