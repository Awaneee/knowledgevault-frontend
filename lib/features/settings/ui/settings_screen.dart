import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/backfill_repository.dart';
import '../data/health_repository.dart';

// ── Local providers (auto-dispose — only needed on this screen) ───────────────

final _healthProvider = FutureProvider.autoDispose<ServerHealth>((ref) {
  return ref.read(healthRepositoryProvider).check();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final user = ref.watch(currentUserProvider);
    final healthAsync = ref.watch(_healthProvider);

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
            children: [
              // ── Appearance ─────────────────────────────────────────────
              const _SectionHeader('Appearance'),
              SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_outlined),
                    label: Text('System'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_outlined),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_outlined),
                    label: Text('Dark'),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (modes) {
                  if (modes.isNotEmpty) {
                    ref.read(themeModeProvider.notifier).setMode(modes.first);
                  }
                },
              ),

              // ── Account ────────────────────────────────────────────────
              if (user != null) ...[
                const _SectionHeader('Account'),
                _Group(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.alternate_email_rounded),
                      title: const Text('Email'),
                      subtitle: Text(user.email),
                    ),
                  ],
                ),
              ],

              // ── AI Features ────────────────────────────────────────────
              const _SectionHeader('AI Features'),
              _Group(
                children: [
                  ListTile(
                    leading: const Icon(Icons.auto_awesome_outlined),
                    title: const Text('Organise my notes'),
                    subtitle: const Text(
                      'Run AI intent detection on notes without a category.',
                    ),
                    trailing: OutlinedButton(
                      onPressed: () => _runBackfill(context, ref),
                      child: const Text('Run'),
                    ),
                  ),
                ],
              ),

              // ── Connection ─────────────────────────────────────────────
              const _SectionHeader('Connection'),
              _Group(
                children: [
                  ListTile(
                    leading: const Icon(Icons.cloud_outlined),
                    title: const Text('Server status'),
                    trailing: healthAsync.when(
                      loading: () => const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (_, __) =>
                          const _StatusDot(ServerHealth.unreachable),
                      data: (h) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainer,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _StatusDot(h),
                            const SizedBox(width: 6),
                            Text(switch (h) {
                              ServerHealth.ok => 'Online',
                              ServerHealth.degraded => 'Degraded',
                              ServerHealth.unreachable => 'Offline',
                            }, style: Theme.of(context).textTheme.labelMedium),
                          ],
                        ),
                      ),
                    ),
                    onTap: () => ref.invalidate(_healthProvider),
                  ),
                ],
              ),

              // ── Logout ─────────────────────────────────────────────────
              const SizedBox(height: 24),
              _Group(
                children: [
                  ListTile(
                    leading: Icon(Icons.logout_rounded, color: cs.error),
                    title: Text('Log out', style: TextStyle(color: cs.error)),
                    onTap: () => ref.read(authProvider.notifier).logout(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runBackfill(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Organise notes?'),
        content: const Text(
          'This runs AI intent detection on your notes. '
          'It may take up to 60 seconds.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Run'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const SimpleDialog(
        contentPadding: EdgeInsets.all(24),
        children: [
          Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Running AI on your notes…\nThis can take 30–60 seconds.',
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'You can close this dialog — processing continues in the background.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );

    try {
      final result = await ref
          .read(backfillRepositoryProvider)
          .run(limit: 50)
          .timeout(const Duration(minutes: 3));
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${result.processed} notes organised'
              '${result.failed > 0 ? ', ${result.failed} failed' : ''}'
              '${result.remainingHint > 0 ? ', ${result.remainingHint} remaining' : ''}.',
            ),
          ),
        );
      }
    } on TimeoutException {
      if (context.mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Still processing in the background — check back in a minute.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

/// Rounded card that holds a group of settings rows.
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(children: children),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot(this.health);

  final ServerHealth health;

  @override
  Widget build(BuildContext context) {
    final color = switch (health) {
      ServerHealth.ok => AppColors.success,
      ServerHealth.degraded => AppColors.warning,
      ServerHealth.unreachable => AppColors.danger,
    };
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
