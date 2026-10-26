import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../notes/ui/widgets/note_card.dart';
import '../../data/models/chunk_result.dart';
import '../../../notes/data/models/note_search_response.dart';

/// Tile for a note-level search result (Smart tab).
class NoteSearchResultTile extends StatelessWidget {
  const NoteSearchResultTile({super.key, required this.result});

  final NoteSearchResponse result;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NoteTile(
        title: result.title,
        content: result.content,
        onTap: () => context.push('/notes/${result.id}'),
      ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.noteTitle,
                style: theme.textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (result.intentCategory != null) ...[
                const SizedBox(height: 6),
                TagPill(
                  label: result.intentCategory!,
                  pastel: Pastel.of(result.intentCategory!),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                result.chunkText,
                style: theme.textTheme.bodySmall,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
