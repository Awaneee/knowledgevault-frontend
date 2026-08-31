import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'answer_bubble.dart' show mdStyleFor;

/// Displays a progressively-built answer string from SSE tokens.
///
/// While [text] is empty (no tokens yet), shows a pulsing dot indicator.
/// Once tokens arrive, renders the accumulated text as markdown.
class StreamAnswerView extends StatelessWidget {
  const StreamAnswerView({
    super.key,
    required this.text,
    required this.isStreaming,
    this.onStop,
  });

  final String text;
  final bool isStreaming;
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
              if (isStreaming && onStop != null)
                IconButton(
                  icon: const Icon(Icons.stop_circle_outlined, size: 20),
                  tooltip: 'Stop',
                  visualDensity: VisualDensity.compact,
                  onPressed: onStop,
                )
              else if (text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  tooltip: 'Copy',
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: text));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
          if (text.isEmpty && isStreaming)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: _TypingIndicator(),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: MarkdownBody(
                data: text,
                selectable: true,
                styleSheet: mdStyleFor(context),
              ),
            ),
          if (isStreaming && text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: cs.surface,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Text(
        '● ● ●',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 4,
        ),
      ),
    );
  }
}
