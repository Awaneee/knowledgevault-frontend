import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/chunk_result.dart';
import '../../../notes/data/models/note_search_response.dart';

/// Tile for a note-level search result (Smart tab).
class NoteSearchResultTile extends StatelessWidget {
  const NoteSearchResultTile({super.key, required this.result});

  final NoteSearchResponse result;

  @override
  Widget build(BuildContext context) {
    final snippet = result.content?.trim() ?? '';
    final preview =
        snippet.length > 120 ? '${snippet.substring(0, 120)}…' : snippet;

    return ListTile(
      leading: const Icon(Icons.note_outlined),
      title: Text(result.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: preview.isNotEmpty
          ? Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis)
          : null,
      onTap: () => context.push('/notes/${result.id}'),
    );
  }
}

/// Tile for a chunk-level search result (Semantic / Chunks tabs).
class ChunkResultTile extends StatelessWidget {
  const ChunkResultTile({super.key, required this.result});

  final ChunkResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.noteTitle,
                style: theme.textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            if (result.intentCategory != null) ...[
              const SizedBox(height: 2),
              Text(result.intentCategory!,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary)),
            ],
            const SizedBox(height: 6),
            Text(result.chunkText,
                style: theme.textTheme.bodySmall,
                maxLines: 4,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
