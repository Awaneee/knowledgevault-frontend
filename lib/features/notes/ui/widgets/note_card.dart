import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../shared/extensions/datetime_ext.dart';
import '../../data/models/note_response.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.categoryName,
  });

  final NoteResponse note;
  final VoidCallback onTap;
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = note.content?.trim() ?? '';
    final snippet = preview.length > 100 ? '${preview.substring(0, 100)}…' : preview;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (snippet.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  snippet,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    note.createdAt.relative,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  if (categoryName != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        categoryName!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer placeholder shown during initial load.
class NoteCardSkeleton extends StatelessWidget {
  const NoteCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlight = Theme.of(context).colorScheme.surface;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 16, width: 200, color: Colors.white),
              const SizedBox(height: 8),
              Container(height: 12, color: Colors.white),
              const SizedBox(height: 4),
              Container(height: 12, width: 160, color: Colors.white),
              const SizedBox(height: 8),
              Container(height: 10, width: 80, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
