import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ambient.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../categories/providers/categories_provider.dart';
import '../../intents/data/models/intent_category_response.dart';
import '../../intents/providers/intents_provider.dart';
import '../../intents/ui/intent_style.dart';
import '../../notes/data/models/note_response.dart';
import '../../notes/providers/notes_provider.dart';
import '../../notes/ui/widgets/note_card.dart';

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
    final needsPolling = notes.any(
      (n) =>
          n.organizationStatus == 'pending' ||
          n.organizationStatus == 'processing',
    );
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
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notesProvider);
              ref.invalidate(intentsProvider);
              ref.invalidate(categoriesProvider);
            },
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    // ── Top bar ────────────────────────────────────────
                    Row(
                      children: [
                        const SparkleOrb(size: 40),
                        const SizedBox(width: 10),
                        Text('KnowledgeVault', style: tt.titleMedium),
                        const Spacer(),
                        Semantics(
                          label: 'Profile',
                          button: true,
                          container: true,
                          excludeSemantics: true,
                          onTap: () => context.push('/profile'),
                          child: Tooltip(
                            message: 'Profile',
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => context.push('/profile'),
                              child: Container(
                                padding: const EdgeInsets.all(2.5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: AppColors.aiGradient(
                                      Theme.of(context).brightness,
                                    ),
                                  ),
                                ),
                                child: UserAvatar(user: user, radius: 19),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Hero ───────────────────────────────────────────
                    TwoToneTitle(
                      '${_greeting()}${user != null ? ',' : '!'}',
                      user != null ? '${user.username}!' : '',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your AI-powered knowledge base',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => context.push('/notes/new'),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('New Note'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.go('/ask'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 52),
                              backgroundColor: AppTheme.cardColor(cs),
                            ),
                            icon: const Icon(Icons.auto_awesome, size: 18),
                            label: const Text('Ask AI'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Stat ───────────────────────────────────────────
                    _StatCard(
                      icon: Icons.sticky_note_2_outlined,
                      label: 'Total Notes',
                      value: noteCount == 0 && notesAsync.isLoading
                          ? '—'
                          : '$noteCount',
                      onTap: () => context.push('/notes'),
                    ),
                    const SizedBox(height: 28),

                    // ── Recent notes ───────────────────────────────────
                    SectionHeader(
                      'Recent notes',
                      action: 'See all',
                      onAction: () => context.push('/notes'),
                    ),
                    _RecentNotesSection(notesAsync: notesAsync),
                    const SizedBox(height: 28),

                    // ── Categories ─────────────────────────────────────
                    SectionHeader(
                      'Categories',
                      action: 'See all',
                      onAction: () => context.go('/categories'),
                    ),
                    categoriesAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (cats) {
                        if (cats.isEmpty) {
                          return const _HintCard(
                            icon: Icons.auto_awesome_outlined,
                            body:
                                'Add notes and AI will automatically '
                                'organise them into categories.',
                          );
                        }
                        final top = _buildGroups(cats).take(6).toList();
                        return LayoutBuilder(
                          builder: (context, c) => GridView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: c.maxWidth >= 600 ? 3 : 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 1.2,
                                ),
                            itemCount: top.length,
                            itemBuilder: (context, i) {
                              final g = top[i];
                              final label = intentLabel(g.intentType);
                              return PastelCard(
                                pastel: intentPastel(g.intentType),
                                icon: intentIcon(g.intentType),
                                title: label,
                                caption: '${g.totalNotes} notes',
                                onTap: () => context.push(
                                  '/categories/t/${g.intentType}',
                                  extra: label,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
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

class _HintCard extends StatelessWidget {
  const _HintCard({
    required this.icon,
    this.title,
    required this.body,
  });

  final IconData icon;
  final String? title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            IconChip(icon, pastel: Pastel.lilac, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(title!, style: tt.titleSmall),
                    const SizedBox(height: 4),
                  ],
                  Text(body, style: tt.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recent-notes section ────────────────────────────────────────────────────

class _RecentNotesSection extends ConsumerWidget {
  const _RecentNotesSection({required this.notesAsync});
  final AsyncValue<List<NoteResponse>> notesAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return notesAsync.when(
      loading: () => const _RecentNotesSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (notes) {
        if (notes.isEmpty) {
          return const _HintCard(
            icon: Icons.edit_note_rounded,
            title: 'No notes yet',
            body: 'Add your first note — AI will organize it for you.',
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
                categoryName: note.categoryId != null
                    ? catById[note.categoryId!]
                    : null,
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NoteTile(
        title: note.title,
        content: note.content,
        onTap: () => context.push('/notes/${note.id}'),
        footer: [
          Text(
            _timeAgo(note.createdAt),
            style: tt.labelSmall?.copyWith(
              color: cs.outline,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          _StatusChip(
            status: note.organizationStatus,
            categoryName: categoryName,
          ),
        ],
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
          return TagPill(
            label: categoryName!,
            pastel: Pastel.of(categoryName!),
            icon: Icons.label_outline,
          );
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
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: tt.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
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
    return Column(
      children: List.generate(
        3,
        (_) => const NoteCardSkeleton(padding: EdgeInsets.only(bottom: 10)),
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
      intentType: e.key,
      totalNotes: total,
      categoryIds: ids,
    );
  }).toList()..sort((a, b) => b.totalNotes.compareTo(a.totalNotes));
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Semantics(
      label: '$value $label',
      button: onTap != null,
      container: true,
      excludeSemantics: true,
      onTap: onTap,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: cs.onSurfaceVariant),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(label, style: tt.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
