import 'package:flutter/material.dart';

import 'ambient.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final Widget? action;
  final IconData icon;

  const EmptyState({
    super.key,
    required this.message,
    this.action,
    this.icon = Icons.auto_awesome_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HaloOrb(
              size: 150,
              child: Icon(icon, size: 36, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
