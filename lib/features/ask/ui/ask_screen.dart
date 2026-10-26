import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ambient.dart';
import '../../../shared/widgets/error_view.dart';
import '../data/ask_repository.dart';
import '../data/models/citation.dart';
import '../providers/ask_provider.dart';
import 'widgets/answer_bubble.dart';
import 'widgets/stream_answer_view.dart';

const _maxQuestion = 2000;

class AskScreen extends ConsumerStatefulWidget {
  const AskScreen({super.key});

  @override
  ConsumerState<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends ConsumerState<AskScreen> {
  final _questionCtrl = TextEditingController();
  bool _loading = false;

  // Last submitted question (for regenerate).
  String? _lastQuestion;

  // Streaming state
  StreamSubscription<AskStreamEvent>? _streamSub;
  String _streamedText = '';
  List<Citation> _streamCitations = const [];
  bool _isStreaming = false;

  @override
  void dispose() {
    _questionCtrl.dispose();
    _streamSub?.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    final question = _questionCtrl.text.trim();
    if (question.isEmpty || _loading) return;
    await _run(question);
  }

  Future<void> _run(String question) async {
    final mode = ref.read(askModeProvider);
    _lastQuestion = question;

    setState(() {
      _loading = true;
      _streamedText = '';
      _streamCitations = const [];
      _isStreaming = false;
    });

    if (mode == AskMode.streaming) {
      await _startStream(question);
    } else {
      await _fullResponse(question);
    }
  }

  void _stopStreaming() {
    _streamSub?.cancel();
    _streamSub = null;
    if (mounted) {
      setState(() {
        _loading = false;
        _isStreaming = false;
      });
    }
  }

  void _regenerate() {
    final q = _lastQuestion;
    if (q == null || q.isEmpty || _loading) return;
    _run(q);
  }

  Future<void> _startStream(String question) async {
    setState(() => _isStreaming = true);

    _streamSub?.cancel();
    final repo = ref.read(askRepositoryProvider);

    _streamSub = repo
        .streamAsk(question)
        .listen(
          (event) {
            if (!mounted) return;
            setState(() {
              switch (event) {
                case AskToken(:final text):
                  _streamedText += text;
                case AskCitations(:final citations):
                  _streamCitations = citations;
              }
            });
          },
          onDone: () {
            if (mounted) {
              setState(() {
                _loading = false;
                _isStreaming = false;
              });
            }
          },
          onError: (error, _) {
            if (mounted) {
              setState(() {
                _loading = false;
                _isStreaming = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${error.toString()}'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
          cancelOnError: true,
        );
  }

  Future<void> _fullResponse(String question) async {
    try {
      await ref.read(askProvider.notifier).ask(question);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clear() {
    _streamSub?.cancel();
    ref.read(askProvider.notifier).clear();
    setState(() {
      _streamedText = '';
      _streamCitations = const [];
      _isStreaming = false;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(askModeProvider);
    final askAsync = ref.watch(askProvider);
    final hasContent =
        _streamedText.isNotEmpty ||
        askAsync.valueOrNull != null ||
        askAsync.hasError;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text('Ask KnowledgeVault'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: OutlinedButton.icon(
              icon: Icon(mode.icon, size: 16),
              label: Text(mode.label),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                backgroundColor: AppTheme.cardColor(
                  Theme.of(context).colorScheme,
                ),
              ),
              onPressed: _loading
                  ? null
                  : () => ref.read(askModeProvider.notifier).toggle(),
            ),
          ),
          if (hasContent)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear',
              onPressed: _clear,
            ),
        ],
      ),
      body: GlowBackground(
        intensity: hasContent ? 0.5 : 1,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: hasContent
                    ? _AnswerArea(
                        mode: mode,
                        streamedText: _streamedText,
                        streamCitations: _streamCitations,
                        isStreaming: _isStreaming,
                        askAsync: askAsync,
                        onGetFullAnswer: _streamedText.isNotEmpty
                            ? () => _fullResponse(
                                _lastQuestion ?? _questionCtrl.text.trim(),
                              )
                            : null,
                        onStop: _isStreaming ? _stopStreaming : null,
                        onRegenerate: _loading || _lastQuestion == null
                            ? null
                            : _regenerate,
                      )
                    : const _EmptyPrompt(),
              ),
              _QuestionInput(
                controller: _questionCtrl,
                loading: _loading,
                onSubmit: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Answer area ───────────────────────────────────────────────────────────────

class _AnswerArea extends StatelessWidget {
  const _AnswerArea({
    required this.mode,
    required this.streamedText,
    required this.streamCitations,
    required this.isStreaming,
    required this.askAsync,
    this.onGetFullAnswer,
    this.onStop,
    this.onRegenerate,
  });

  final AskMode mode;
  final String streamedText;
  final List<Citation> streamCitations;
  final bool isStreaming;
  final AsyncValue<dynamic> askAsync;
  final VoidCallback? onGetFullAnswer;
  final VoidCallback? onStop;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        // Streaming mode output
        if (mode == AskMode.streaming &&
            (streamedText.isNotEmpty || isStreaming)) ...[
          StreamAnswerView(
            text: streamedText,
            citations: streamCitations,
            isStreaming: isStreaming,
            onStop: onStop,
          ),
          if (streamedText.isNotEmpty && !isStreaming) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: [
                if (onRegenerate != null)
                  TextButton.icon(
                    onPressed: onRegenerate,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Regenerate'),
                  ),
                if (onGetFullAnswer != null)
                  TextButton(
                    onPressed: onGetFullAnswer,
                    child: const Text('View full answer with citations →'),
                  ),
              ],
            ),
          ],
        ],

        // Full mode output
        if (mode == AskMode.full)
          askAsync.when(
            loading: () => const StreamAnswerView(text: '', isStreaming: true),
            error: (e, _) => ErrorView(message: e.toString()),
            data: (response) {
              if (response == null) return const SizedBox.shrink();
              return response.isDegraded
                  ? DegradedAnswerView(response: response)
                  : AnswerBubble(
                      response: response,
                      onRegenerate: onRegenerate,
                    );
            },
          ),
      ],
    );
  }
}

// ── Question input bar ────────────────────────────────────────────────────────

class _QuestionInput extends StatelessWidget {
  const _QuestionInput({
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
          hintText: 'Ask a question about your notes…',
          maxLength: _maxQuestion,
        ),
      ),
    );
  }
}

/// Rounded prompt field with a gradient send button, shared with chats.
class PromptBar extends StatelessWidget {
  const PromptBar({
    super.key,
    required this.controller,
    required this.loading,
    required this.onSubmit,
    required this.hintText,
    this.maxLength,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSubmit;
  final String hintText;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colors = AppColors.aiGradient(Theme.of(context).brightness);

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(cs),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLength: maxLength,
              maxLines: 4,
              minLines: 1,
              buildCounter:
                  (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
              enabled: !loading,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                hintText: hintText,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 46,
            height: 46,
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(13),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Semantics(
                    label: 'Send',
                    button: true,
                    container: true,
                    excludeSemantics: true,
                    onTap: onSubmit,
                    child: Tooltip(
                      message: 'Send',
                      child: Material(
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: colors,
                            ),
                          ),
                          child: InkWell(
                            onTap: onSubmit,
                            child: const Icon(
                              Icons.arrow_upward_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Empty prompt ──────────────────────────────────────────────────────────────

class _EmptyPrompt extends StatelessWidget {
  const _EmptyPrompt();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HaloOrb(
              size: 230,
              child: Icon(Icons.auto_awesome, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask a question about your notes.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
