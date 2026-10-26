import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/ambient.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../intents/data/models/intent_category_response.dart';
import '../../intents/providers/intents_provider.dart';
import '../../intents/ui/intent_style.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(intentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: categoriesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(intentsProvider),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return const EmptyState(
              icon: Icons.folder_open_rounded,
              message:
                  'No categories yet.\nNotes are auto-organised by AI when you add them.',
            );
          }

          final groups = _groupByIntentType(categories);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(intentsProvider),
            child: LayoutBuilder(
              builder: (context, c) => CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                    sliver: SliverGrid.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: c.maxWidth >= 900
                            ? 4
                            : c.maxWidth >= 600
                            ? 3
                            : 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.05,
                      ),
                      itemCount: groups.length,
                      itemBuilder: (context, i) {
                        final group = groups[i];
                        final label = intentLabel(group.intentType);
                        return PastelCard(
                          pastel: intentPastel(group.intentType),
                          icon: intentIcon(group.intentType),
                          title: label,
                          caption:
                              '${group.totalNotes} ${group.totalNotes == 1 ? 'note' : 'notes'}',
                          onTap: () => context.push(
                            '/categories/t/${group.intentType}',
                            extra: label,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
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

List<_IntentGroup> _groupByIntentType(List<IntentCategoryResponse> categories) {
  final map = <String, List<IntentCategoryResponse>>{};
  for (final c in categories) {
    map.putIfAbsent(c.intentType, () => []).add(c);
  }

  // Sort groups by total note count descending.
  return map.entries.map((e) {
    final total = e.value.fold(0, (s, c) => s + c.noteCount);
    final ids = e.value.map((c) => c.id).toList();
    return _IntentGroup(intentType: e.key, categoryIds: ids, totalNotes: total);
  }).toList()..sort((a, b) => b.totalNotes.compareTo(a.totalNotes));
}
