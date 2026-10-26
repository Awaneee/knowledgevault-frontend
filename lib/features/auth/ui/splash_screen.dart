import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/ambient.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching authProvider triggers initialization. When build() resolves it
    // updates authStatusProvider, which fires the router redirect.
    ref.watch(authProvider);

    return const Scaffold(
      body: GlowBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SparkleOrb(size: 76),
              SizedBox(height: 28),
              TwoToneTitle(
                'Knowledge',
                'Vault',
                textAlign: TextAlign.center,
                size: 34,
              ),
              SizedBox(height: 32),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
