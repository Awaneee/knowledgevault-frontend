import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ambient.dart';
import '../../ask/ui/ask_screen.dart' show PromptBar;
import '../../ask/ui/widgets/answer_bubble.dart' show mdStyleFor;
import '../data/conversations_repository.dart';
import '../data/models/conversation_message.dart';
import '../providers/conversations_provider.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<ConversationMessage> _messages = [];
  bool _loading = false;
  String? _sessionTitle;
  bool _initialized = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Load session on first build.
    final detailAsync = ref.watch(conversationDetailProvider(widget.sessionId));

    return detailAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(e.toString())),
      ),
      data: (detail) {
        if (!_initialized) {
          _messages
            ..clear()
            ..addAll(detail.messages);
          _sessionTitle = detail.title;
          _initialized = true;
        }
        return _buildChat(context);
      },
    );
  }

  Widget _buildChat(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _sessionTitle ?? 'Conversation',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _EmptyState()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _messages.length) {
                        return const _TypingIndicator();
                      }
                      return _MessageBubble(message: _messages[i]);
                    },
                  ),
          ),
          _InputBar(controller: _ctrl, loading: _loading, onSubmit: _send),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;

    final userMsg = ConversationMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      role: 'user',
      content: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _loading = true;
      _ctrl.clear();
    });
    _scrollToBottom();

    try {
      final result = await ref
          .read(conversationsRepositoryProvider)
          .askInSession(widget.sessionId, text);

      final assistantMsg = ConversationMessage(
        id: DateTime.now().millisecondsSinceEpoch + 1,
        role: 'assistant',
        content: result['answer'] as String? ?? '',
        citations: result['citations'] as List<dynamic>?,
        createdAt: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _messages.add(assistantMsg);
          _loading = false;
          _sessionTitle ??= text.length > 60
              ? '${text.substring(0, 57)}…'
              : text;
        });
        _scrollToBottom();
        // Refresh the sessions list so title/count updates.
        ref.invalidate(conversationsProvider);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

// ── Bubble ────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ConversationMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final scheme = Theme.of(context).colorScheme;

    final bubbleColor = isUser ? scheme.primary : AppTheme.cardColor(scheme);
    final textColor = isUser ? scheme.onPrimary : scheme.onSurface;

    final citations = message.citations ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const SparkleOrb(size: 28),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    border: isUser
                        ? null
                        : Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.6),
                          ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(22),
                      topRight: const Radius.circular(22),
                      bottomLeft: Radius.circular(isUser ? 22 : 6),
                      bottomRight: Radius.circular(isUser ? 6 : 22),
                    ),
                  ),
                  child: isUser
                      ? SelectableText(
                          message.content,
                          style: TextStyle(color: textColor, height: 1.4),
                        )
                      : MarkdownBody(
                          data: message.content,
                          selectable: true,
                          styleSheet: mdStyleFor(context).copyWith(
                            p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: textColor,
                              height: 1.4,
                            ),
                          ),
                        ),
                ),
                if (citations.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _CitationRow(citations: citations),
                ],
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _CitationRow extends StatelessWidget {
  const _CitationRow({required this.citations});
  final List<dynamic> citations;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 4,
      children: citations.take(3).map((c) {
        final title =
            (c as Map<String, dynamic>)['note_title'] as String? ?? 'Note';
        return Chip(
          label: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11),
          ),
          avatar: Icon(Icons.link, size: 12, color: scheme.primary),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const SparkleOrb(size: 28),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.cardColor(scheme),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: const SizedBox(
              width: 40,
              height: 16,
              child: Center(child: LinearProgressIndicator(minHeight: 2)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.loading,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: PromptBar(
          controller: controller,
          loading: loading,
          onSubmit: onSubmit,
          hintText: 'Continue the conversation…',
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HaloOrb(
              size: 180,
              child: Icon(Icons.forum_outlined, size: 36, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const TwoToneTitle(
              'Start the',
              'conversation',
              textAlign: TextAlign.center,
              size: 28,
            ),
            const SizedBox(height: 10),
            Text(
              'Your AI assistant remembers the full chat history',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
