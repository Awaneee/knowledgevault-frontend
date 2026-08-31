import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/citation.dart';

/// Shows a citation bottom sheet with snippet and navigation.
void showCitationSheet(BuildContext context, Citation citation) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CitationSheet(citation: citation),
  );
}

class _CitationSheet extends StatelessWidget {
  const _CitationSheet({required this.citation});

  final Citation citation;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(label: Text('[${citation.ref}]')),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    citation.noteTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                citation.snippet,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Go to note'),
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/notes/${citation.noteId}');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
