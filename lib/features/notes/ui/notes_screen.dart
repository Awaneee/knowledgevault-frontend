import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../categories/data/models/category_response.dart';
import '../../categories/providers/categories_provider.dart';
import '../data/models/note_response.dart';
import '../providers/notes_provider.dart';
import 'widgets/note_card.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  int? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/notes/new'),
        tooltip: 'New note',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (categories.isNotEmpty)
            _CategoryFilterBar(
              categories: categories,
              selectedId: _selectedCategoryId,
              onSelected: (id) => setState(() => _selectedCategoryId = id),
            ),
          Expanded(
            child: notesAsync.when(
              loading: () => _SkeletonList(),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.read(notesProvider.notifier).refresh(),
              ),
              data: (notes) {
                final filtered = _selectedCategoryId == null
                    ? notes
                    : notes
                        .where((n) => n.categoryId == _selectedCategoryId)
                        .toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    message: notes.isEmpty
                        ? "You haven't added any notes yet."
                        : 'No notes in this category.',
                    action: notes.isEmpty
                        ? FilledButton(
                            onPressed: () => context.push('/notes/new'),
                            child: const Text('Add your first note'),
                          )
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(notesProvider.notifier).refresh(),
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final note = filtered[i];
                      final category = note.categoryId == null
                          ? null
                          : categories
                              .where((c) => c.id == note.categoryId)
                              .firstOrNull;

                      return _SwipeToDelete(
                        key: ValueKey(note.id),
                        noteId: note.id,
                        onDelete: () => _deleteNote(note),
                        child: NoteCard(
                          note: note,
                          categoryName: category?.name,
                          onTap: () => context.push('/notes/${note.id}'),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNote(NoteResponse note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text('"${note.title}" will be permanently deleted.'),
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
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(notesProvider.notifier).deleteNote(note.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${note.title}" deleted')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to delete note. Please try again.')),
        );
      }
    }
  }
}

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<CategoryResponse> categories;
  final int? selectedId;
  final void Function(int?) onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: selectedId == null,
            onSelected: (_) => onSelected(null),
          ),
          ...categories.map((c) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: FilterChip(
                  label: Text(c.name),
                  selected: selectedId == c.id,
                  onSelected: (sel) => onSelected(sel ? c.id : null),
                ),
              )),
        ],
      ),
    );
  }
}

class _SwipeToDelete extends StatelessWidget {
  const _SwipeToDelete({
    super.key,
    required this.noteId,
    required this.child,
    required this.onDelete,
  });

  final int noteId;
  final Widget child;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(noteId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Theme.of(context).colorScheme.error,
        child: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.onError,
        ),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // Provider handles the removal.
      },
      child: child,
    );
  }
}

class _SkeletonList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, __) => const NoteCardSkeleton(),
    );
  }
}
