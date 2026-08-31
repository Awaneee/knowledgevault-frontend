import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../data/ask_repository.dart';
import '../data/models/ask_response.dart';

// ── Mode toggle ───────────────────────────────────────────────────────────────

enum AskMode { streaming, full }

final askModeProvider =
    NotifierProvider<AskModeNotifier, AskMode>(AskModeNotifier.new);

class AskModeNotifier extends Notifier<AskMode> {
  static const _key = 'kv_ask_mode';

  @override
  AskMode build() {
    final value = ref.read(sharedPreferencesProvider).getString(_key);
    return value == 'full' ? AskMode.full : AskMode.streaming;
  }

  Future<void> toggle() async {
    final next = state == AskMode.streaming ? AskMode.full : AskMode.streaming;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_key, next.name);
    state = next;
  }
}

// ── Full-response provider ────────────────────────────────────────────────────

final askProvider =
    AsyncNotifierProvider<AskNotifier, AskResponse?>(AskNotifier.new);

class AskNotifier extends AsyncNotifier<AskResponse?> {
  @override
  Future<AskResponse?> build() async => null;

  Future<void> ask(String question) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(askRepositoryProvider).ask(question),
    );
  }

  void clear() => state = const AsyncData(null);
}

// ── Streaming helper ──────────────────────────────────────────────────────────

/// Returns the raw [Stream<String>] from the SSE endpoint.
/// Consumed directly in [AskScreen] via a [StreamSubscription].
Stream<String> askStream(AskRepository repo, String question) =>
    repo.streamAsk(question);

// ── Re-export for convenience ─────────────────────────────────────────────────

// ignore: non_constant_identifier_names
final AskModeLabel = {
  AskMode.streaming: 'Streaming',
  AskMode.full: 'Full',
};

// Needed by AskScreen for semantic labelling — keep in one place.
extension AskModeExt on AskMode {
  String get label => switch (this) {
        AskMode.streaming => 'Streaming',
        AskMode.full => 'Full response',
      };

  IconData get icon => switch (this) {
        AskMode.streaming => Icons.stream,
        AskMode.full => Icons.format_quote,
      };
}
