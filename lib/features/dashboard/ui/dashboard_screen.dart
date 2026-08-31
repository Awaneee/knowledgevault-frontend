import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../categories/providers/categories_provider.dart';
import '../../intents/data/models/intent_category_response.dart';
import '../../intents/providers/intents_provider.dart';
import '../../notes/data/models/note_response.dart';
import '../../notes/providers/notes_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Poll notes every 4s while any note is still being organized. Stops
  /// automatically once every note has landed in `organized` (or `failed`).
  void _syncPolling(List<NoteResponse> notes) {
    final needsPolling = notes.any((n) =>
        n.organizationStatus == 'pending' ||
        n.organizationStatus == 'processing');
    if (needsPolling) {
      _pollTimer ??= Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        ref.invalidate(notesProvider);
      });
    } else if (_pollTimer != null) {
      _pollTimer!.cancel();
      _pollTimer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final notesAsync = ref.watch(notesProvider);
    final categoriesAsync = ref.watch(intentsProvider);

    // Kick polling on/off based on current note state.
    notesAsync.whenData(_syncPolling);

    final notes = notesAsync.valueOrNull ?? const <NoteResponse>[];
    final noteCount = notes.length;
    final greeting = _greeting();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('KnowledgeVault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notesProvider);
          ref.invalidate(intentsProvider);
          ref.invalidate(categoriesProvider);
        },
        child: ListView(
          children: [
            // ── Hero ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              color: cs.primaryContainer,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting${user != null ? ', ${user.username}' : ''}!',
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your AI-powered knowledge base',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.push('/notes/new'),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('New Note'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.go('/ask'),
                          icon: const Icon(Icons.auto_awesome, size: 18),
                          label: const Text('Ask AI'),
                          style: FilledButton.styleFrom(
                            backgroundColor: cs.secondaryContainer,
                            foregroundColor: cs.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatCard(
                    icon: Icons.note_alt_outlined,
                    label: 'Total Notes',
                    value: noteCount == 0 && notesAsync.isLoading
                        ? '—'
                        : '$noteCount',
                    onTap: () => context.push('/notes'),
                  ),
                  const SizedBox(height: 24),

                  // ── Recent notes ─────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent notes', style: tt.titleMedium),
                      TextButton(
                        onPressed: () => context.push('/notes'),
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _RecentNotesSection(notesAsync: notesAsync),

                  const SizedBox(height: 24),

                  // ── Categories ───────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Categories', style: tt.titleMedium),
                      TextButton(
                        onPressed: () => context.go('/categories'),
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  categoriesAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (cats) {
                      if (cats.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Icon(Icons.auto_awesome_outlined,
                                    color: cs.primary, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Add notes and AI will automatically '
                                    'organise them into categories.',
                                    style: tt.bodyMedium
                                        ?.copyWith(color: cs.onSurfaceVariant),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final groups = _buildGroups(cats);
                      final top = groups.take(6).toList();
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.4,
                        ),
                        itemCount: top.length,
                        itemBuilder: (context, i) =>
                            _CategoryCard(group: top[i]),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

// ── Recent-notes section ────────────────────────────────────────────────────

class _RecentNotesSection extends ConsumerWidget {
  const _RecentNotesSection({required this.notesAsync});
  final AsyncValue<List<NoteResponse>> notesAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return notesAsync.when(
      loading: () => const _RecentNotesSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (notes) {
        if (notes.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.edit_note, color: cs.primary, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('No notes yet',
                            style: tt.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          'Add your first note — AI will organize it for you.',
                          style: tt.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final sorted = [...notes]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final recent = sorted.take(5).toList();

        // Resolve categoryId → name once for the whole list.
        final categoriesAsync = ref.watch(categoriesProvider);
        final catById = <int, String>{
          for (final c in categoriesAsync.valueOrNull ?? const []) c.id: c.name,
        };

        return Column(
          children: [
            for (final note in recent)
              _RecentNoteCard(
                note: note,
                categoryName:
                    note.categoryId != null ? catById[note.categoryId!] : null,
              ),
          ],
        );
      },
    );
  }
}

class _RecentNoteCard extends StatelessWidget {
  const _RecentNoteCard({required this.note, this.categoryName});
  final NoteResponse note;
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final preview = (note.content ?? '').trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.push('/notes/${note.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title,
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  preview,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    _timeAgo(note.createdAt),
                    style: tt.bodySmall?.copyWith(color: cs.outline),
                  ),
                  const Spacer(),
                  _StatusChip(
                    status: note.organizationStatus,
                    categoryName: categoryName,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, this.categoryName});
  final String? status;
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    Color bg;
    Color fg;
    Widget leading;
    String label;

    switch (status) {
      case 'pending':
      case 'processing':
        bg = cs.tertiaryContainer;
        fg = cs.onTertiaryContainer;
        leading = SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.6,
            valueColor: AlwaysStoppedAnimation(fg),
          ),
        );
        label = 'Organizing…';
        break;
      case 'failed':
        bg = cs.errorContainer;
        fg = cs.onErrorContainer;
        leading = Icon(Icons.error_outline, size: 12, color: fg);
        label = 'Failed';
        break;
      case 'organized':
      default:
        if (categoryName != null && categoryName!.isNotEmpty) {
          bg = cs.primaryContainer;
          fg = cs.onPrimaryContainer;
          leading = Icon(Icons.label_outline, size: 12, color: fg);
          label = categoryName!;
        } else {
          bg = cs.surfaceContainerHighest;
          fg = cs.onSurfaceVariant;
          leading = Icon(Icons.check_circle_outline, size: 12, color: fg);
          label = 'Organized';
        }
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: tt.labelSmall
                    ?.copyWith(color: fg, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentNotesSkeleton extends StatelessWidget {
  const _RecentNotesSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: List.generate(
        3,
        (_) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    height: 14,
                    width: 180,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    )),
                const SizedBox(height: 8),
                Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.day}/${dt.month}/${dt.year}';
}

// ── Category group model ─────────────────────────────────────────────────────

class _CategoryGroup {
  const _CategoryGroup({
    required this.intentType,
    required this.totalNotes,
    required this.categoryIds,
  });
  final String intentType;
  final int totalNotes;
  final List<int> categoryIds;
}

List<_CategoryGroup> _buildGroups(List<IntentCategoryResponse> cats) {
  final map = <String, List<IntentCategoryResponse>>{};
  for (final c in cats) {
    map.putIfAbsent(c.intentType, () => []).add(c);
  }
  return map.entries.map((e) {
    final total = e.value.fold(0, (s, c) => s + c.noteCount);
    final ids = e.value.map((c) => c.id).toList();
    return _CategoryGroup(
        intentType: e.key, totalNotes: total, categoryIds: ids);
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

// ── Widgets ──────────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.group});
  final _CategoryGroup group;

  @override
  Widget build(BuildContext context) {
    final label = _intentLabel(group.intentType);
    final icon = _intentIcon(group.intentType);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onTap: () => context.push(
          '/categories/t/${group.intentType}',
          extra: label,
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: cs.primary),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${group.totalNotes} notes',
                style: tt.bodySmall?.copyWith(color: cs.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: cs.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: tt.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    label,
                    style: tt.bodySmall?.copyWith(color: cs.outline),
                  ),
                ],
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }
}
