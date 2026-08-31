import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/attachments_repository.dart';
import '../../providers/attachments_provider.dart';

class UploadButton extends ConsumerStatefulWidget {
  const UploadButton({super.key, required this.noteId});

  final int noteId;

  @override
  ConsumerState<UploadButton> createState() => _UploadButtonState();
}

class _UploadButtonState extends ConsumerState<UploadButton> {
  bool _uploading = false;
  double? _progress;

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'docx', 'png', 'jpg', 'jpeg'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;

    setState(() {
      _uploading = true;
      _progress = 0;
    });

    try {
      await ref.read(attachmentsRepositoryProvider).upload(
            noteId: widget.noteId,
            filePath: file.path!,
            filename: file.name,
            onProgress: (sent, total) {
              if (total > 0 && mounted) {
                setState(() => _progress = sent / total);
              }
            },
          );
      // Invalidate so the attachment list refreshes.
      ref.invalidate(attachmentsProvider(widget.noteId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          _progress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uploading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Uploading…'),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: _progress),
        ],
      );
    }
    return TextButton.icon(
      icon: const Icon(Icons.attach_file),
      label: const Text('Add attachment'),
      onPressed: _pick,
    );
  }
}
