import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Logs unhandled [AsyncError] provider states.
/// In debug mode: prints to console. In release: no-op (errors surfaced by UI).
class KvProviderObserver extends ProviderObserver {
  const KvProviderObserver();

  @override
  void didUpdateProvider(
    ProviderBase<dynamic> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (newValue is AsyncError && kDebugMode) {
      debugPrint(
        '[KvProviderObserver] ${provider.name ?? provider.runtimeType} '
        'error: ${newValue.error}\n${newValue.stackTrace}',
      );
    }
  }
}
