import 'dart:typed_data';

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

  /// PATCH /auth/me — rename the account. Throws [ConflictException] (via
  /// [ErrorHandler]) if the username is already taken.
  Future<UserResponse> updateUsername(String username) async {
    try {
      final response = await _dio.patch(
        '/auth/me',
        data: {'username': username},
      );
      return UserResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }

  /// POST /auth/me/avatar — upload/replace the profile picture.
  Future<UserResponse> uploadAvatar({
    required String filePath,
    required String filename,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: filename),
      });
      final response = await _dio.post('/auth/me/avatar', data: formData);
      return UserResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }

  /// DELETE /auth/me/avatar — remove the profile picture.
  Future<UserResponse> deleteAvatar() async {
    try {
      final response = await _dio.delete('/auth/me/avatar');
      return UserResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.fromDioException(e);
    }
  }

  /// GET /auth/me/avatar — raw image bytes, or null if none is set.
  Future<Uint8List?> getAvatarBytes() async {
    try {
      final response = await _dio.get<List<int>>(
        '/auth/me/avatar',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? const []);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ErrorHandler.fromDioException(e);
    }
  }
}
