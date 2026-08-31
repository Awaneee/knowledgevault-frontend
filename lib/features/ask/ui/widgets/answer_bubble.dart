import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../data/models/ask_response.dart';
import '../../data/models/citation.dart';
import 'citation_card.dart';

/// Renders the AI answer as markdown with tappable citation links.
///
/// LLMs return markdown (headings, lists, code, bold) — we render it properly
/// via [MarkdownBody]. Inline `[N]` citation refs are rewritten to markdown
/// links (`[\[N\]](cite://N)`) so they become tappable.
class AnswerBubble extends StatelessWidget {
  const AnswerBubble({
    super.key,
    required this.response,
    this.onRegenerate,
  });

  final AskResponse response;
  final VoidCallback? onRegenerate;

  static final _citationPattern = RegExp(r'\[(\d+)\]');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final citationRefs = {for (final c in response.citations) c.ref};
    final markdown = _linkifyCitations(response.answer, citationRefs);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text('Answer',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
              const Spacer(),
              if (onRegenerate != null)
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Regenerate',
                  visualDensity: VisualDensity.compact,
                  onPressed: onRegenerate,
                ),
              IconButton(
                icon: const Icon(Icons.copy_outlined, size: 18),
                tooltip: 'Copy',
                visualDensity: VisualDensity.compact,
                onPressed: () => _copyToClipboard(context, response.answer),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: MarkdownBody(
              data: markdown,
              selectable: true,
              styleSheet: mdStyleFor(context),
              onTapLink: (text, href, title) {
                if (href != null && href.startsWith('cite://')) {
                  final n = int.tryParse(href.substring(7));
                  Citation? citation;
                  for (final c in response.citations) {
                    if (c.ref == n) {
                      citation = c;
                      break;
                    }
                  }
                  if (citation != null) showCitationSheet(context, citation);
                }
              },
            ),
          ),
          if (response.citations.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(color: cs.outlineVariant),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text('Sources',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: response.citations
                    .map((c) => ActionChip(
                          visualDensity: VisualDensity.compact,
                          label: Text('[${c.ref}] ${c.noteTitle}',
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          onPressed: () => showCitationSheet(context, c),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _linkifyCitations(String answer, Set<int> validRefs) {
    return answer.replaceAllMapped(_citationPattern, (m) {
      final n = int.tryParse(m.group(1) ?? '');
      if (n == null || !validRefs.contains(n)) return m.group(0)!;
      return '[\\[$n\\]](cite://$n)';
    });
  }

  static Future<void> _copyToClipboard(
      BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

/// Shared markdown styling for LLM output. Kept top-level so streaming and
/// full-answer views render identically.
MarkdownStyleSheet mdStyleFor(BuildContext context) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  return MarkdownStyleSheet.fromTheme(theme).copyWith(
    p: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
    a: theme.textTheme.labelSmall?.copyWith(
      color: cs.onPrimaryContainer,
      backgroundColor: cs.primaryContainer,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.none,
    ),
    code: theme.textTheme.bodySmall?.copyWith(
      fontFamily: 'monospace',
      backgroundColor: cs.surfaceContainer,
    ),
    codeblockDecoration: BoxDecoration(
      color: cs.surfaceContainer,
      borderRadius: BorderRadius.circular(8),
    ),
    codeblockPadding: const EdgeInsets.all(12),
    h1: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    h2: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    h3: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    listBullet: theme.textTheme.bodyMedium,
    blockquoteDecoration: BoxDecoration(
      color: cs.surfaceContainer,
      border: Border(left: BorderSide(color: cs.primary, width: 3)),
    ),
    blockquotePadding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
  );
}

/// Degraded mode — shows chunk previews when the LLM is unavailable.
class DegradedAnswerView extends StatelessWidget {
  const DegradedAnswerView({super.key, required this.response});

  final AskResponse response;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_outlined,
                  color: Theme.of(context).colorScheme.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI answer unavailable — showing relevant notes instead.',
                  style: TextStyle(
                      color:
                          Theme.of(context).colorScheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...response.chunks.map(
          (chunk) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(chunk.title,
                            style: Theme.of(context).textTheme.titleSmall),
                      ),
                      Text(
                        chunk.score.toStringAsFixed(2),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(chunk.preview,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
