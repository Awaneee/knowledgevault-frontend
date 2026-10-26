import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/ambient.dart';
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
    final tt = Theme.of(context).textTheme;
    final type = attachment.fileType.toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              IconChip(
                type.contains('PDF')
                    ? Icons.picture_as_pdf_outlined
                    : type.contains('PNG') || type.contains('JP')
                    ? Icons.image_outlined
                    : Icons.insert_drive_file_outlined,
                pastel: Pastel.of(type),
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.filename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.titleSmall,
                    ),
                    Text(type, style: tt.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
