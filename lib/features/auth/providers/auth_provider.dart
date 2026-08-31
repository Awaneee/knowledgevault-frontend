import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/auth/token_storage.dart';
import '../data/auth_repository.dart';
import '../data/models/login_request.dart';
import '../data/models/register_request.dart';
import '../data/models/user_response.dart';

/// Async notifier that owns the authenticated user.
///
/// Lifecycle:
///   build()     — reads stored token, validates via GET /auth/me
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
      ref.read(authStatusProvider.notifier).setAuthenticated();
      return user;
    } on UnauthorizedException {
      await tokenStorage.delete();
      ref.read(authStatusProvider.notifier).setUnauthenticated();
      return null;
    } on Exception {
      // Network error or timeout — treat as unauthenticated so the app
      // doesn't block on splash forever.
      ref.read(authStatusProvider.notifier).setUnauthenticated();
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final tokenStorage = ref.read(tokenStorageProvider);

      final token = await repo.login(LoginRequest(email: email, password: password));
      await tokenStorage.save(token.accessToken);

      final user = await repo.getMe();
      ref.read(authStatusProvider.notifier).setAuthenticated();
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).delete();
    ref.read(authStatusProvider.notifier).setUnauthenticated();
    state = const AsyncData(null);
  }

  /// Registers a new account. Does NOT log in — caller navigates to login.
  Future<void> register(RegisterRequest request) async {
    await ref.read(authRepositoryProvider).register(request);
  }
}
