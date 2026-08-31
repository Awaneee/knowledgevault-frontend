import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/notes_provider.dart';

const _maxLength = 50000;
const _warnLength = 45000;

class CreateNoteScreen extends ConsumerStatefulWidget {
  const CreateNoteScreen({super.key});

  @override
  ConsumerState<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends ConsumerState<CreateNoteScreen> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() => _saving = true);
    try {
      final response =
          await ref.read(notesProvider.notifier).createNote(content);
      if (mounted) context.go('/notes/${response.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save note. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _importFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'docx'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;

    setState(() => _saving = true);
    try {
      final noteId = await ref
          .read(notesProvider.notifier)
          .uploadFile(file.path!, file.name);
      if (mounted) context.go('/notes/$noteId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final charCount = _controller.text.length;
    final atLimit = charCount >= _maxLength;
    final nearLimit = charCount >= _warnLength;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Note'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _controller.text.trim().isEmpty ? null : _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                maxLines: null,
                maxLength: _maxLength,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                    null, // We render the counter ourselves below.
                expands: true,
                enabled: !_saving,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Start writing…',
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Import file'),
                  onPressed: _saving ? null : _importFile,
                ),
                const Spacer(),
                Text(
                  '$charCount / $_maxLength',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: atLimit
                            ? Theme.of(context).colorScheme.error
                            : nearLimit
                                ? Theme.of(context).colorScheme.tertiary
                                : Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
