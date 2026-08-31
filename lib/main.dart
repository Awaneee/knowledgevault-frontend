import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/error/provider_observer.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      observers: const [KvProviderObserver()],
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const KnowledgeVaultApp(),
    ),
  );
}
