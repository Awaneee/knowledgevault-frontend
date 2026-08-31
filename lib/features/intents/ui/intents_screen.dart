import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../providers/intents_provider.dart';
import 'widgets/intent_category_tile.dart';

class IntentsScreen extends ConsumerWidget {
  const IntentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intentsAsync = ref.watch(intentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Organisation')),
      body: intentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(intentsProvider),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return const EmptyState(
              message:
                  'Notes are still being organised.\nTry adding more notes.',
            );
          }
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, i) => IntentCategoryTile(
              category: categories[i],
              onTap: () => context.push('/intents/${categories[i].id}/notes'),
            ),
          );
        },
      ),
    );
  }
}
