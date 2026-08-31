import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../attachments/data/attachments_repository.dart';
import '../../attachments/data/models/attachment_response.dart';
import '../../intents/data/intents_repository.dart';
import '../../intents/data/models/note_intent_response.dart';
import '../data/models/note_response.dart';
import '../data/models/related_note_response.dart';
import '../data/notes_repository.dart';

final noteDetailProvider =
    FutureProvider.autoDispose.family<NoteResponse, int>((ref, id) {
  return ref.read(notesRepositoryProvider).getNote(id);
});

final relatedNotesProvider =
    FutureProvider.autoDispose.family<List<RelatedNoteResponse>, int>((ref, id) {
  return ref.read(notesRepositoryProvider).getRelatedNotes(id);
});

/// Returns null when the note has no intent (404).
final noteIntentProvider =
    FutureProvider.autoDispose.family<NoteIntentResponse?, int>((ref, id) {
  return ref.read(intentsRepositoryProvider).getNoteIntent(id);
});

final noteAttachmentsProvider =
    FutureProvider.autoDispose.family<List<AttachmentResponse>, int>((ref, id) {
  return ref.read(attachmentsRepositoryProvider).listForNote(id);
});
