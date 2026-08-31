import 'package:flutter/foundation.dart';

import 'app_flavor.dart';

/// Build-time configuration injected via --dart-define flags.
///
/// Dev (Android emulator):
///   flutter run --dart-define=FLAVOR=dev
///
/// Dev (physical device / custom URL):
///   flutter run --dart-define=FLAVOR=dev --dart-define=BASE_URL=http://192.168.1.x:8000
///
/// Prod:
///   flutter run --dart-define=FLAVOR=prod
abstract final class AppConfig {
  static const _flavorRaw = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  static const _baseUrlRaw = String.fromEnvironment('BASE_URL', defaultValue: '');

  static AppFlavor get flavor => switch (_flavorRaw) {
        'prod' => AppFlavor.prod,
        'staging' => AppFlavor.staging,
        _ => AppFlavor.dev,
      };

  /// Backend base URL.
  ///
  /// Resolution order:
  ///   1. `--dart-define=BASE_URL=<url>` (explicit override)
  ///   2. Flavor default (dev → Android emulator localhost)
  static const _railwayUrl =
      'https://knowledgevault-production-8903.up.railway.app';

  static String get baseUrl {
    if (_baseUrlRaw.isNotEmpty) return _baseUrlRaw;
    return switch (flavor) {
      AppFlavor.prod => _railwayUrl,
      AppFlavor.staging => _railwayUrl,
      // Dev: desktop uses localhost, Android emulator uses 10.0.2.2
      AppFlavor.dev => (kIsWeb ||
              defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.linux)
          ? 'http://localhost:8000'
          : 'http://10.0.2.2:8000',
    };
  }

  static bool get isDebug => flavor == AppFlavor.dev;
}
