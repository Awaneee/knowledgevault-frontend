import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../providers/topics_provider.dart';

class TopicsScreen extends ConsumerWidget {
  const TopicsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(topicsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Topics')),
      body: topicsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(topicsProvider),
        ),
        data: (topics) {
          if (topics.isEmpty) {
            return const EmptyState(
              message:
                  'Add more notes to see AI-generated topics.',
            );
          }
          return ListView.builder(
            itemCount: topics.length,
            itemBuilder: (context, i) {
              final topic = topics[i];
              return ExpansionTile(
                leading: const Icon(Icons.topic_outlined),
                title: Text(topic.topicName),
                trailing: Chip(
                  label: Text('${topic.notes.length}'),
                  padding: EdgeInsets.zero,
                ),
                children: topic.notes
                    .map(
                      (note) => ListTile(
                        leading: const Icon(Icons.note_outlined),
                        title: Text(
                          note.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        dense: true,
                        onTap: () => context.push('/notes/${note.id}'),
                      ),
                    )
                    .toList(),
              );
            },
          );
        },
      ),
    );
  }
}
