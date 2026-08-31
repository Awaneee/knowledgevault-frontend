import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/connectivity/connectivity_banner.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class KnowledgeVaultApp extends ConsumerWidget {
  const KnowledgeVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'KnowledgeVault',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => ConnectivityBanner(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
