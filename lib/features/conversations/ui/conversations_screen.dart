import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/extensions/datetime_ext.dart';
import '../../../shared/widgets/ambient.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../data/models/conversation_session.dart';
import '../providers/conversations_provider.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(conversationsProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('New chat'),
        onPressed: () => _createAndOpen(context, ref),
      ),
      body: sessionsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(conversationsProvider.notifier).refresh(),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return const EmptyState(
              icon: Icons.forum_outlined,
              message:
                  'No conversations yet\n'
                  'Start a new chat to ask multi-turn questions',
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(conversationsProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
              itemCount: sessions.length,
              itemBuilder: (context, i) => _SessionTile(session: sessions[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _createAndOpen(BuildContext context, WidgetRef ref) async {
    try {
      final session = await ref
          .read(conversationsProvider.notifier)
          .createSession();
      if (context.mounted) {
        context.push('/conversations/${session.id}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _SessionTile extends ConsumerWidget {
  const _SessionTile({required this.session});
  final ConversationSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final title = session.title ?? 'New conversation';

    return Dismissible(
      key: ValueKey(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete conversation?'),
          content: const Text('This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
      onDismissed: (_) =>
          ref.read(conversationsProvider.notifier).deleteSession(session.id),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          child: InkWell(
            onTap: () => context.push('/conversations/${session.id}'),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  IconChip(
                    Icons.forum_outlined,
                    pastel: Pastel.of(session.id),
                    size: 46,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${session.messageCount} messages · ${session.updatedAt.relative}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.outline),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: scheme.outline),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
