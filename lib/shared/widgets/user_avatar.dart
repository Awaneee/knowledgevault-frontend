import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/models/user_response.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Circular profile picture for [user], falling back to their initial on a
/// tinted background while the image loads, on fetch failure, or when no
/// picture has been set.
class UserAvatar extends ConsumerWidget {
  const UserAvatar({super.key, required this.user, this.radius = 20});

  final UserResponse? user;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final initial = (user?.username.isNotEmpty ?? false)
        ? user!.username[0].toUpperCase()
        : '?';

    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: cs.primaryContainer,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.w600,
          color: cs.onPrimaryContainer,
        ),
      ),
    );

    if (user == null || !user!.hasAvatar) return fallback;

    final avatarAsync = ref.watch(avatarProvider);
    return avatarAsync.when(
      data: (bytes) => bytes == null
          ? fallback
          : CircleAvatar(
              radius: radius,
              backgroundImage: MemoryImage(bytes),
            ),
      loading: () => CircleAvatar(
        radius: radius,
        backgroundColor: cs.primaryContainer,
        child: SizedBox(
          width: radius * 0.7,
          height: radius * 0.7,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: cs.onPrimaryContainer,
          ),
        ),
      ),
      error: (_, __) => fallback,
    );
  }
}
