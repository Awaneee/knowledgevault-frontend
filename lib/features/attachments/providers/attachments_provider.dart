import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/attachments_repository.dart';
import '../data/models/attachment_response.dart';

final attachmentsProvider =
    FutureProvider.autoDispose.family<List<AttachmentResponse>, int>((ref, noteId) {
  return ref.read(attachmentsRepositoryProvider).listForNote(noteId);
});
