import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

final authStatusProvider = NotifierProvider<AuthStatusNotifier, AuthStatus>(
  AuthStatusNotifier.new,
);

class AuthStatusNotifier extends Notifier<AuthStatus> {
  @override
  AuthStatus build() => AuthStatus.unknown;

  void setAuthenticated() => state = AuthStatus.authenticated;
  void setUnauthenticated() => state = AuthStatus.unauthenticated;
}

/// Set to true by [AuthInterceptor] on a 401 response so [LoginScreen]
/// can show a "Session expired" banner. Reset after the banner is shown.
final sessionExpiredProvider = StateProvider<bool>((ref) => false);
