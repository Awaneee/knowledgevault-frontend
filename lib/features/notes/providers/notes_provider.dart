import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/local_cache.dart';
import '../data/models/note_create_response.dart';
import '../data/models/note_response.dart';
import '../data/notes_repository.dart';

final notesProvider =
    AsyncNotifierProvider<NotesNotifier, List<NoteResponse>>(NotesNotifier.new);

class NotesNotifier extends AsyncNotifier<List<NoteResponse>> {
  @override
  Future<List<NoteResponse>> build() async {
    final db = ref.read(appDatabaseProvider);

    // Serve cached rows immediately while fetching fresh data.
    final cachedRows = await db.getCachedNoteRows();
    if (cachedRows.isNotEmpty) {
      // Seed the state with cached data so the UI isn't blank.
      state = AsyncData(_rowsToNotes(cachedRows));
    }

    final notes = await ref.read(notesRepositoryProvider).listNotes();
    await db.cacheNoteRows(_notesToRows(notes));
    return notes;
  }

  Future<NoteCreateResponse> createNote(String content) async {
    final response =
        await ref.read(notesRepositoryProvider).createNote(content);
    // Prepend to current list without a full reload.
    final current = state.valueOrNull ?? [];
    state = AsyncData([
      NoteResponse(
        id: response.id,
        title: response.title,
        content: response.content,
        userId: response.userId,
        categoryId: response.categoryId,
        organizationStatus: response.organizationStatus,
        createdAt: response.createdAt,
      ),
      ...current,
    ]);
    return response;
  }

  /// Optimistic category change: updates state immediately, rolls back on failure.
  Future<void> updateCategory(int noteId, int? categoryId) async {
    final previous = state.valueOrNull ?? [];
    state = AsyncData([
      for (final n in previous)
        if (n.id == noteId)
          NoteResponse(
            id: n.id,
            title: n.title,
            content: n.content,
            userId: n.userId,
            categoryId: categoryId,
            autoTitleSource: n.autoTitleSource,
            organizationStatus: 'organized',
            createdAt: n.createdAt,
          )
        else
          n,
    ]);
    try {
      await ref.read(notesRepositoryProvider).updateCategory(noteId, categoryId);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  /// Optimistic delete: removes from state immediately, rolls back on failure.
  Future<void> deleteNote(int id) async {
    final previous = state.valueOrNull ?? [];
    state = AsyncData(previous.where((n) => n.id != id).toList());
    try {
      await ref.read(notesRepositoryProvider).deleteNote(id);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<int> uploadFile(String filePath, String filename) async {
    return ref.read(notesRepositoryProvider).uploadFile(filePath, filename);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(notesRepositoryProvider).listNotes(),
    );
    final notes = state.valueOrNull;
    if (notes != null) {
      await ref.read(appDatabaseProvider).cacheNoteRows(_notesToRows(notes));
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static List<NoteResponse> _rowsToNotes(List<Map<String, dynamic>> rows) =>
      rows
          .map((r) => NoteResponse(
                id: r['id'] as int,
                title: r['title'] as String,
                content: r['content'] as String?,
                userId: r['user_id'] as int,
                categoryId: r['category_id'] as int?,
                organizationStatus: r['organization_status'] as String?,
                createdAt: DateTime.parse(r['created_at'] as String),
              ))
          .toList();

  static List<Map<String, dynamic>> _notesToRows(List<NoteResponse> notes) =>
      notes
          .map((n) => {
                'id': n.id,
                'title': n.title,
                'content': n.content,
                'user_id': n.userId,
                'category_id': n.categoryId,
                'organization_status': n.organizationStatus,
                'created_at': n.createdAt.toIso8601String(),
              })
          .toList();
}
