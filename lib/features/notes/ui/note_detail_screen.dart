import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ambient.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../attachments/ui/widgets/attachment_list.dart';
import '../../attachments/ui/widgets/upload_button.dart';
import '../../categories/data/models/category_response.dart';
import '../../categories/providers/categories_provider.dart';
import '../data/models/note_response.dart';
import '../data/models/related_note_response.dart';
import '../providers/note_detail_provider.dart';
import '../providers/notes_provider.dart';

class NoteDetailScreen extends ConsumerWidget {
  const NoteDetailScreen({super.key, required this.noteId});

  final int noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteDetailProvider(noteId));

    return Scaffold(
      appBar: AppBar(
        actions: [
          noteAsync.maybeWhen(
            data: (_) => PopupMenuButton<String>(
              tooltip: 'More options',
              icon: const Icon(Icons.more_horiz_rounded),
              onSelected: (value) {
                if (value == 'delete') _confirmDelete(context, ref);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('Delete note'),
                    ],
                  ),
                ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: noteAsync.when(
        loading: () => const LoadingOverlay(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(noteDetailProvider(noteId)),
        ),
        data: (note) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
          children: [
            Text(note.title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 18),
            if (note.content != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SelectableText(
                    note.content!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.6),
                  ),
                ),
              ),
            const SizedBox(height: 14),

            // ── Category picker ─────────────────────────────────────────
            _CategoryRow(note: note),
            const SizedBox(height: 24),

            // ── Related notes ────────────────────────────────────────────
            _RelatedNotesSection(noteId: noteId),

            // ── Attachments ──────────────────────────────────────────────
            _SectionHeader(
              title: 'Attachments',
              trailing: UploadButton(noteId: noteId),
            ),
            AttachmentList(noteId: noteId),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This note will be permanently deleted.'),
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

    if (confirmed != true || !context.mounted) return;
    await ref.read(notesProvider.notifier).deleteNote(noteId);
    if (context.mounted) context.pop();
  }
}

class _RelatedNotesSection extends ConsumerWidget {
  const _RelatedNotesSection({required this.noteId});

  final int noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relatedAsync = ref.watch(relatedNotesProvider(noteId));

    return relatedAsync.maybeWhen(
      data: (related) {
        if (related.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(title: 'Related Notes'),
            ...related.map((r) => _RelatedNoteTile(note: r)),
            const SizedBox(height: 16),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _RelatedNoteTile extends StatelessWidget {
  const _RelatedNoteTile({required this.note});
  final RelatedNoteResponse note;

  @override
  Widget build(BuildContext context) {
    final pct = (note.similarity * 100).toStringAsFixed(0);
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          onTap: () => context.push('/notes/${note.noteId}'),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconChip(
                  Icons.description_outlined,
                  pastel: Pastel.of(note.noteId),
                  size: 42,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.titleSmall,
                      ),
                      if (note.snippet.isNotEmpty)
                        Text(
                          note.snippet,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '$pct%',
                    style: tt.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow({required this.note});
  final NoteResponse note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories =
        categoriesAsync.valueOrNull ?? const <CategoryResponse>[];
    final current = note.categoryId == null
        ? null
        : categories.firstWhere(
            (c) => c.id == note.categoryId,
            orElse: () => const CategoryResponse(id: -1, name: ''),
          );
    final currentName = (current == null || current.id == -1)
        ? 'Uncategorized'
        : current.name;

    final hasCategory = current != null && current.id != -1;

    return Material(
      color: AppTheme.cardColor(cs),
      shape: StadiumBorder(
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        onTap: () => _openPicker(context, ref),
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: hasCategory
                      ? Pastel.of(currentName).gradient
                      : null,
                  color: hasCategory ? null : cs.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.label_outline_rounded,
                  size: 18,
                  color: hasCategory ? AppColors.onPastel : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Category',
                style: tt.labelMedium?.copyWith(color: cs.outline),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  currentName,
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.edit_outlined, size: 18, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context, WidgetRef ref) async {
    final categories = ref.read(categoriesProvider).valueOrNull ?? const [];
    final selected = await showModalBottomSheet<_CategorySelection>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _CategoryPickerSheet(
        categories: categories,
        currentCategoryId: note.categoryId,
      ),
    );
    if (selected == null) return;
    // "no change" case
    if (selected.categoryId == note.categoryId) return;
    try {
      await ref
          .read(notesProvider.notifier)
          .updateCategory(note.id, selected.categoryId);
      ref.invalidate(noteDetailProvider(note.id));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Category updated')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't update category")),
        );
      }
    }
  }
}

class _CategorySelection {
  const _CategorySelection(this.categoryId);
  final int? categoryId;
}

class _CategoryPickerSheet extends ConsumerStatefulWidget {
  const _CategoryPickerSheet({
    required this.categories,
    required this.currentCategoryId,
  });
  final List<CategoryResponse> categories;
  final int? currentCategoryId;

  @override
  ConsumerState<_CategoryPickerSheet> createState() =>
      _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends ConsumerState<_CategoryPickerSheet> {
  String _query = '';
  final _newNameCtrl = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _newNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.categories
        : widget.categories
              .where((c) => c.name.toLowerCase().contains(q))
              .toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 4,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Choose category',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, const _CategorySelection(null)),
                  child: const Text('Uncategorize'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search or type a new name…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                fillColor: cs.surfaceContainer,
              ),
              onChanged: (v) {
                setState(() => _query = v);
                _newNameCtrl.text = v;
              },
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        q.isEmpty
                            ? 'No categories yet. Type a name to create one.'
                            : 'No match. Tap "Create" below to add.',
                        style: tt.bodySmall?.copyWith(color: cs.outline),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        final selected = c.id == widget.currentCategoryId;
                        return ListTile(
                          leading: Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: selected ? cs.primary : cs.outline,
                          ),
                          title: Text(c.name),
                          onTap: () =>
                              Navigator.pop(context, _CategorySelection(c.id)),
                        );
                      },
                    ),
            ),
            if (_query.trim().isNotEmpty &&
                !widget.categories.any(
                  (c) => c.name.toLowerCase() == _query.trim().toLowerCase(),
                )) ...[
              const Divider(height: 24),
              FilledButton.icon(
                onPressed: _creating ? null : _createAndSelect,
                icon: _creating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add, size: 18),
                label: Text('Create "${_query.trim()}"'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _createAndSelect() async {
    setState(() => _creating = true);
    try {
      final newCat = await ref
          .read(categoriesProvider.notifier)
          .createCategory(_query.trim());
      if (!mounted) return;
      Navigator.pop(context, _CategorySelection(newCat.id));
    } catch (_) {
      if (mounted) {
        setState(() => _creating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't create category")),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
