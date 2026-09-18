import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/cache/local_cache.dart';
import '../../../core/connectivity/connectivity_banner.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/models/note_create_response.dart';
import '../data/models/note_response.dart';
import '../data/notes_repository.dart';

final notesProvider =
    AsyncNotifierProvider<NotesNotifier, List<NoteResponse>>(NotesNotifier.new);

/// Status shown on a note that was written offline and hasn't reached the
/// server yet.
const pendingSyncStatus = 'pending_sync';

/// Local placeholder notes use the negative of their queue id, so they can
/// never collide with a server id.
bool isPendingNoteId(int id) => id < 0;

class NotesNotifier extends AsyncNotifier<List<NoteResponse>> {
  bool _syncing = false;

  @override
  Future<List<NoteResponse>> build() async {
    final db = ref.read(appDatabaseProvider);

    // Back online → send anything written while offline.
    ref.listen<AsyncValue<List<ConnectivityResult>>>(connectivityProvider,
        (_, next) {
      final results = next.valueOrNull;
      if (results != null && !isOffline(results)) syncPending();
    });

    final pending = await _pendingPlaceholders();

    // Serve cached rows immediately while fetching fresh data.
    final cachedRows = await db.getCachedNoteRows();
    final cached = _rowsToNotes(cachedRows);
    if (cachedRows.isNotEmpty || pending.isNotEmpty) {
      // Seed the state with cached data so the UI isn't blank.
      state = AsyncData([...pending, ...cached]);
    }

    try {
      var notes = await ref.read(notesRepositoryProvider).listNotes();
      await db.cacheNoteRows(_notesToRows(notes));

      // We just reached the server, so flush the offline queue now.
      if (pending.isNotEmpty && await _flushQueue() > 0) {
        notes = await ref.read(notesRepositoryProvider).listNotes();
        await db.cacheNoteRows(_notesToRows(notes));
      }
      return [...await _pendingPlaceholders(), ...notes];
    } on NetworkException {
      // Offline: show what we have; only fail if we have nothing at all.
      if (cachedRows.isNotEmpty || pending.isNotEmpty) {
        return [...pending, ...cached];
      }
      rethrow;
    }
  }

  /// Creates a note. Returns the server's response, or `null` when the device
  /// is offline and the note was queued to sync later.
  Future<NoteCreateResponse?> createNote(String content) async {
    try {
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
    } on NetworkException {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) rethrow;
      final opId = await ref
          .read(appDatabaseProvider)
          .enqueueCreateNote(userId: userId, content: content);
      final current = state.valueOrNull ?? [];
      state = AsyncData([
        _placeholder(
          opId: opId,
          userId: userId,
          content: content,
          createdAt: DateTime.now(),
        ),
        ...current,
      ]);
      return null;
    }
  }

  /// Sends queued offline writes to the server. Safe to call any time; it
  /// stops quietly when the server can't be reached. Returns how many synced.
  Future<int> syncPending() async {
    final synced = await _flushQueue();
    if (synced > 0) {
      try {
        final notes = await ref.read(notesRepositoryProvider).listNotes();
        await ref.read(appDatabaseProvider).cacheNoteRows(_notesToRows(notes));
        state = AsyncData([...await _pendingPlaceholders(), ...notes]);
      } catch (_) {
        // Keep the current list; the next refresh will catch up.
      }
    }
    return synced;
  }

  Future<int> _flushQueue() async {
    if (_syncing) return 0;
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return 0;

    _syncing = true;
    var synced = 0;
    try {
      final db = ref.read(appDatabaseProvider);
      final repo = ref.read(notesRepositoryProvider);
      for (final op in await db.getPendingOps(userId)) {
        if (op.kind != PendingOp.createNote) {
          await db.deletePendingOp(op.id);
          continue;
        }
        try {
          await repo.createNote(op.payload);
          await db.deletePendingOp(op.id);
          synced++;
        } on NetworkException {
          break; // still offline
        } on ServerException {
          break; // server trouble — retry later
        } on UnauthorizedException {
          break; // session expired — retry after sign-in
        } on RateLimitException {
          break;
        } on ApiException {
          // The server rejected this note for good (validation etc.). Drop it
          // so one bad entry can't block the rest of the queue forever.
          await db.deletePendingOp(op.id);
        }
      }
    } finally {
      _syncing = false;
    }
    return synced;
  }

  Future<List<NoteResponse>> _pendingPlaceholders() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return const [];
    final ops = await ref.read(appDatabaseProvider).getPendingOps(userId);
    return [
      for (final op in ops.reversed) // newest first, like the server list
        if (op.kind == PendingOp.createNote)
          _placeholder(
            opId: op.id,
            userId: userId,
            content: op.payload,
            createdAt: op.createdAt,
          ),
    ];
  }

  static NoteResponse _placeholder({
    required int opId,
    required int userId,
    required String content,
    required DateTime createdAt,
  }) {
    final firstLine = content
        .split('\n')
        .map((l) => l.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => 'New note');
    return NoteResponse(
      id: -opId,
      title: firstLine.length > 60 ? '${firstLine.substring(0, 60)}…' : firstLine,
      content: content,
      userId: userId,
      organizationStatus: pendingSyncStatus,
      createdAt: createdAt,
    );
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
    if (isPendingNoteId(id)) {
      // Never reached the server: just drop it from the queue.
      await ref.read(appDatabaseProvider).deletePendingOp(-id);
      return;
    }
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
    await _flushQueue();
    final previous = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final notes = await ref.read(notesRepositoryProvider).listNotes();
        await ref.read(appDatabaseProvider).cacheNoteRows(_notesToRows(notes));
        return [...await _pendingPlaceholders(), ...notes];
      } on NetworkException {
        // Offline pull-to-refresh: keep showing what we have.
        if (previous != null) return previous;
        rethrow;
      }
    });
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
