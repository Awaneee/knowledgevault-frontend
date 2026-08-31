import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../intents/data/models/intent_category_response.dart';
import '../../intents/providers/intents_provider.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(intentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(intentsProvider),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return const EmptyState(
              message:
                  'No categories yet.\nNotes are auto-organised by AI when you add them.',
            );
          }

          final groups = _groupByIntentType(categories);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(intentsProvider),
            child: ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, i) {
                final group = groups[i];
                return ListTile(
                  leading: Icon(_intentIcon(group.intentType)),
                  title: Text(_intentLabel(group.intentType)),
                  trailing: Text(
                    '${group.totalNotes} ${group.totalNotes == 1 ? 'note' : 'notes'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  onTap: () => context.push(
                    '/categories/t/${group.intentType}',
                    extra: _intentLabel(group.intentType),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/notes/new'),
        tooltip: 'New note',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ── Grouping helpers ──────────────────────────────────────────────────────────

class _IntentGroup {
  const _IntentGroup({
    required this.intentType,
    required this.categoryIds,
    required this.totalNotes,
  });
  final String intentType;
  final List<int> categoryIds;
  final int totalNotes;
}

List<_IntentGroup> _groupByIntentType(
    List<IntentCategoryResponse> categories) {
  final map = <String, List<IntentCategoryResponse>>{};
  for (final c in categories) {
    map.putIfAbsent(c.intentType, () => []).add(c);
  }

  // Sort groups by total note count descending.
  return map.entries.map((e) {
    final total = e.value.fold(0, (s, c) => s + c.noteCount);
    final ids = e.value.map((c) => c.id).toList();
    return _IntentGroup(intentType: e.key, categoryIds: ids, totalNotes: total);
  }).toList()
    ..sort((a, b) => b.totalNotes.compareTo(a.totalNotes));
}

String _intentLabel(String type) => switch (type) {
      'todo' => 'Tasks',
      'study' => 'Study',
      'question' => 'Questions',
      'communication' => 'Messages',
      'reference' => 'Reference',
      'idea' => 'Ideas',
      'reminder' => 'Reminders',
      'event' => 'Events',
      _ => 'General',
    };

IconData _intentIcon(String type) => switch (type) {
      'todo' => Icons.check_circle_outline,
      'study' => Icons.school_outlined,
      'question' => Icons.help_outline,
      'communication' => Icons.chat_bubble_outline,
      'reference' => Icons.bookmark_outline,
      'idea' => Icons.lightbulb_outline,
      'reminder' => Icons.alarm_outlined,
      'event' => Icons.event_outlined,
      _ => Icons.notes_outlined,
    };
