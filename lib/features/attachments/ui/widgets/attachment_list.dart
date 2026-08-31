import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/attachment_response.dart';
import '../../providers/attachments_provider.dart';

class AttachmentList extends ConsumerWidget {
  const AttachmentList({super.key, required this.noteId});

  final int noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(attachmentsProvider(noteId));

    return async.when(
      loading: () => const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (attachments) {
        if (attachments.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: attachments
              .map((a) => _AttachmentTile(attachment: a))
              .toList(),
        );
      },
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.attachment});

  final AttachmentResponse attachment;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.insert_drive_file_outlined),
      title: Text(
        attachment.filename,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(attachment.fileType.toUpperCase()),
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}
