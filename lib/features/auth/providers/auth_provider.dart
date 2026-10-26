import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/cache/local_cache.dart';
import '../../../core/auth/token_storage.dart';
import '../data/auth_repository.dart';
import '../data/models/login_request.dart';
import '../data/models/register_request.dart';
import '../data/models/user_response.dart';

/// Async notifier that owns the authenticated user.
///
/// Lifecycle:
///   build()     — reads stored token, validates via GET /auth/me; if the
///                 server is unreachable, keeps the user signed in from the
///                 profile cached at the last successful sign-in
///   login()     — POST /auth/login → store token → GET /auth/me
///   logout()    — delete token → clear state
///   register()  — POST /auth/register (does NOT log the user in)
final authProvider =
    AsyncNotifierProvider<AuthNotifier, UserResponse?>(AuthNotifier.new);

/// Convenience read: the current user without caring about async state.
/// Null when unauthenticated or while loading.
final currentUserProvider = Provider<UserResponse?>((ref) {
  return ref.watch(authProvider).valueOrNull;
});

/// The current user's profile picture, refetched whenever [authProvider]
/// emits a new user (login, username change, avatar upload/removal).
/// Null when the user has no avatar set; an error surfaces if the fetch
/// itself fails (caller can fall back to initials either way).
final avatarProvider = FutureProvider.autoDispose<Uint8List?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.hasAvatar) return null;
  return ref.read(authRepositoryProvider).getAvatarBytes();
});

class AuthNotifier extends AsyncNotifier<UserResponse?> {
  @override
  Future<UserResponse?> build() async {
    final tokenStorage = ref.read(tokenStorageProvider);
    final token = await tokenStorage.read().timeout(
      const Duration(seconds: 5),
      onTimeout: () => null,
    );

    if (token == null) {
      ref.read(authStatusProvider.notifier).setUnauthenticated();
      return null;
    }

    try {
      final user = await ref.read(authRepositoryProvider).getMe();
      await _cacheUser(user);
      ref.read(authStatusProvider.notifier).setAuthenticated();
      return user;
    } on UnauthorizedException {
      await tokenStorage.delete();
      ref.read(authStatusProvider.notifier).setUnauthenticated();
      return null;
    } on NetworkException {
      return _offlineUser();
    } on ServerException {
      return _offlineUser();
    } on Exception {
      // Network error or timeout — treat as unauthenticated so the app
      // doesn't block on splash forever.
      ref.read(authStatusProvider.notifier).setUnauthenticated();
      return null;
    }
  }

  static const _userCacheKey = 'current_user';

  Future<void> _cacheUser(UserResponse user) async {
    try {
      await ref
          .read(appDatabaseProvider)
          .setKv(_userCacheKey, jsonEncode(user.toJson()));
    } catch (_) {
      // Caching is best-effort; never block sign-in on it.
    }
  }

  /// The server can't be reached but a token is stored: stay signed in as the
  /// last known user so the cached notes and offline queue remain usable.
  /// Without a cached profile there's nothing to show, so fall back to
  /// signed-out as before.
  Future<UserResponse?> _offlineUser() async {
    try {
      final raw = await ref.read(appDatabaseProvider).getKv(_userCacheKey);
      if (raw != null) {
        final user =
            UserResponse.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        ref.read(authStatusProvider.notifier).setAuthenticated();
        return user;
      }
    } catch (_) {}
    ref.read(authStatusProvider.notifier).setUnauthenticated();
    return null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final tokenStorage = ref.read(tokenStorageProvider);

      final token = await repo.login(LoginRequest(email: email, password: password));
      await tokenStorage.save(token.accessToken);

      final user = await repo.getMe();
      await _cacheUser(user);
      ref.read(authStatusProvider.notifier).setAuthenticated();
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).delete();
    await ref.read(appDatabaseProvider).clearCachedData();
    ref.read(authStatusProvider.notifier).setUnauthenticated();
    state = const AsyncData(null);
  }

  /// Registers a new account. Does NOT log in — caller navigates to login.
  Future<void> register(RegisterRequest request) async {
    await ref.read(authRepositoryProvider).register(request);
  }

  /// Renames the account. Throws (e.g. [ConflictException]) if the
  /// username is taken — caller shows the message and state is untouched.
  Future<void> updateUsername(String username) async {
    final user = await ref.read(authRepositoryProvider).updateUsername(username);
    state = AsyncData(user);
  }

  /// Uploads/replaces the profile picture from a local file.
  Future<void> uploadAvatar(MultipartFile file) async {
    final user =
        await ref.read(authRepositoryProvider).uploadAvatar(file: file);
    state = AsyncData(user);
  }

  /// Removes the profile picture.
  Future<void> deleteAvatar() async {
    final user = await ref.read(authRepositoryProvider).deleteAvatar();
    state = AsyncData(user);
  }
}
