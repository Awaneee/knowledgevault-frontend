import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: NoteTile(
        title: note.title,
        content: note.content,
        onTap: onTap,
        footer: [
          Text(
            note.createdAt.relative,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (note.id < 0) ...[
            // Written offline; not on the server yet.
            const SizedBox(width: 8),
            Icon(
              Icons.cloud_off_outlined,
              size: 14,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: 4),
            Text(
              'Waiting to sync',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
          if (categoryName != null) ...[
            const Spacer(),
            TagPill(label: categoryName!, pastel: Pastel.of(categoryName!)),
          ],
        ],
      ),
    );
  }
}

/// White (or plum, in dark mode) rounded card showing a note's title, a
/// two-line preview and a footer row. Shared by every note list.
class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.title,
    required this.content,
    required this.onTap,
    this.footer = const [],
  });

  final String title;
  final String? content;
  final VoidCallback onTap;
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = content?.trim() ?? '';
    final snippet = preview.length > 140
        ? '${preview.substring(0, 140)}…'
        : preview;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (snippet.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  snippet,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (footer.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(children: footer),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small pastel pill used for category names.
class TagPill extends StatelessWidget {
  const TagPill({
    super.key,
    required this.label,
    required this.pastel,
    this.icon,
  });

  final String label;
  final Pastel pastel;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 170),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: pastel.gradient,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: AppColors.onPastel),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.onPastel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder shown during initial load.
class NoteCardSkeleton extends StatelessWidget {
  const NoteCardSkeleton({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
  });

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHigh;
    final highlight = Theme.of(context).colorScheme.surfaceContainerLow;

    Widget bar(double? w, double h) => Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Padding(
        padding: padding,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(200, 16),
                const SizedBox(height: 10),
                bar(null, 12),
                const SizedBox(height: 6),
                bar(160, 12),
                const SizedBox(height: 12),
                bar(80, 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
