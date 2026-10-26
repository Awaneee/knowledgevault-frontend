import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/extensions/platform_file_ext.dart';
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
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (!file.isReadable) return;

    setState(() {
      _uploading = true;
      _progress = 0;
    });

    try {
      await ref.read(attachmentsRepositoryProvider).upload(
            noteId: widget.noteId,
            file: await file.toMultipart(),
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
      return SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Uploading…', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(value: _progress, minHeight: 6),
            ),
          ],
        ),
      );
    }
    return OutlinedButton.icon(
      icon: const Icon(Icons.attach_file_rounded, size: 18),
      label: const Text('Add attachment'),
      style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
      onPressed: _pick,
    );
  }
}
