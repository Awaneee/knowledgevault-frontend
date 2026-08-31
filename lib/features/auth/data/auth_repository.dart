import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/error/error_handler.dart';
import 'models/login_request.dart';
import 'models/register_request.dart';
import 'models/token_response.dart';
import 'models/user_response.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(apiClientProvider).dio);
});

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<TokenResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: request.toJson(),
      );
      return TokenResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }

  Future<UserResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: request.toJson(),
      );
      return UserResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _dio.post('/auth/reset-password', data: {
        'email': email,
        'code': code,
        'new_password': newPassword,
      });
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }

  Future<UserResponse> getMe() async {
    try {
      final response = await _dio.get('/auth/me');
      return UserResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }
}
