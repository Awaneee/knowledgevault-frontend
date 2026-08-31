import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/error_view.dart';
import '../data/ask_repository.dart';
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
  StreamSubscription<String>? _streamSub;
  String _streamedText = '';
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

    _streamSub = repo.streamAsk(question).listen(
      (token) {
        if (mounted) setState(() => _streamedText += token);
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
      _isStreaming = false;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(askModeProvider);
    final askAsync = ref.watch(askProvider);
    final hasContent = _streamedText.isNotEmpty ||
        askAsync.valueOrNull != null ||
        askAsync.hasError;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask KnowledgeVault'),
        actions: [
          TextButton.icon(
            icon: Icon(mode.icon, size: 18),
            label: Text(mode.label),
            onPressed: _loading
                ? null
                : () => ref.read(askModeProvider.notifier).toggle(),
          ),
          if (hasContent)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear',
              onPressed: _clear,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: hasContent
                ? _AnswerArea(
                    mode: mode,
                    streamedText: _streamedText,
                    isStreaming: _isStreaming,
                    askAsync: askAsync,
                    onGetFullAnswer: _streamedText.isNotEmpty
                        ? () => _fullResponse(
                            _lastQuestion ?? _questionCtrl.text.trim())
                        : null,
                    onStop: _isStreaming ? _stopStreaming : null,
                    onRegenerate:
                        _loading || _lastQuestion == null ? null : _regenerate,
                  )
                : const _EmptyPrompt(),
          ),
          const Divider(height: 1),
          _QuestionInput(
            controller: _questionCtrl,
            loading: _loading,
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }
}

// ── Answer area ───────────────────────────────────────────────────────────────

class _AnswerArea extends StatelessWidget {
  const _AnswerArea({
    required this.mode,
    required this.streamedText,
    required this.isStreaming,
    required this.askAsync,
    this.onGetFullAnswer,
    this.onStop,
    this.onRegenerate,
  });

  final AskMode mode;
  final String streamedText;
  final bool isStreaming;
  final AsyncValue<dynamic> askAsync;
  final VoidCallback? onGetFullAnswer;
  final VoidCallback? onStop;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Streaming mode output
        if (mode == AskMode.streaming && (streamedText.isNotEmpty || isStreaming)) ...[
          StreamAnswerView(
            text: streamedText,
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
            loading: () => const StreamAnswerView(
                text: '', isStreaming: true),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLength: _maxQuestion,
                maxLines: 4,
                minLines: 1,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                    null,
                enabled: !loading,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSubmit(),
                decoration: const InputDecoration(
                  hintText: 'Ask a question about your notes…',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            loading
                ? const SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton.filled(
                    icon: const Icon(Icons.send),
                    tooltip: 'Send',
                    onPressed: onSubmit,
                  ),
          ],
        ),
      ),
    );
  }
}

// ── Empty prompt ──────────────────────────────────────────────────────────────

class _EmptyPrompt extends StatelessWidget {
  const _EmptyPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Ask a question about your notes.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
