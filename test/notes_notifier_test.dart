import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledgevault/core/api/api_client.dart';
import 'package:knowledgevault/core/api/api_exceptions.dart';
import 'package:knowledgevault/core/cache/local_cache.dart';
import 'package:knowledgevault/features/notes/data/models/note_create_response.dart';
import 'package:knowledgevault/features/notes/data/models/note_response.dart';
import 'package:knowledgevault/features/notes/data/notes_repository.dart';
import 'package:knowledgevault/features/notes/providers/notes_provider.dart';
import 'package:mocktail/mocktail.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockNotesRepository extends Mock implements NotesRepository {}

class MockApiClient extends Mock implements ApiClient {}

class MockAppDatabase extends Mock implements AppDatabase {}

// ── Helpers ───────────────────────────────────────────────────────────────────

NoteResponse _note(int id) => NoteResponse(
      id: id,
      title: 'Note $id',
      userId: 1,
      createdAt: DateTime(2026, 1, id),
    );

ProviderContainer _makeContainer(MockNotesRepository repo) {
  final db = MockAppDatabase();
  when(() => db.getCachedNoteRows()).thenAnswer((_) async => []);
  when(() => db.cacheNoteRows(any())).thenAnswer((_) async {});
  when(() => db.close()).thenAnswer((_) async {});

  return ProviderContainer(
    overrides: [
      notesRepositoryProvider.overrideWithValue(repo),
      appDatabaseProvider.overrideWithValue(db),
    ],
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockNotesRepository repo;

  setUp(() {
    repo = MockNotesRepository();
  });

  group('NotesNotifier', () {
    test('loads notes from repository on build', () async {
      final notes = [_note(1), _note(2)];
      when(() => repo.listNotes()).thenAnswer((_) async => notes);

      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final result = await container.read(notesProvider.future);
      expect(result, equals(notes));
    });

    test('optimistic delete removes note immediately', () async {
      final notes = [_note(1), _note(2), _note(3)];
      when(() => repo.listNotes()).thenAnswer((_) async => notes);
      when(() => repo.deleteNote(2)).thenAnswer((_) async {});

      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await container.read(notesProvider.future);

      // Act — delete note 2
      await container.read(notesProvider.notifier).deleteNote(2);

      final remaining = container.read(notesProvider).valueOrNull ?? [];
      expect(remaining.map((n) => n.id), containsAll([1, 3]));
      expect(remaining.any((n) => n.id == 2), isFalse);
    });

    test('optimistic delete rolls back on API failure', () async {
      final notes = [_note(1), _note(2)];
      when(() => repo.listNotes()).thenAnswer((_) async => notes);
      when(() => repo.deleteNote(1))
          .thenThrow(const ServerException('Server error'));

      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await container.read(notesProvider.future);

      await expectLater(
        () => container.read(notesProvider.notifier).deleteNote(1),
        throwsA(isA<ServerException>()),
      );

      // Both notes should be restored
      final current = container.read(notesProvider).valueOrNull ?? [];
      expect(current.length, equals(2));
    });

    test('createNote prepends to list', () async {
      when(() => repo.listNotes()).thenAnswer((_) async => [_note(1)]);
      when(() => repo.createNote(any())).thenAnswer(
        (_) async => NoteCreateResponse(
          id: 99,
          title: 'New note',
          userId: 1,
          createdAt: DateTime.now(),
        ),
      );

      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await container.read(notesProvider.future);
      await container.read(notesProvider.notifier).createNote('New content');

      final current = container.read(notesProvider).valueOrNull ?? [];
      expect(current.first.id, equals(99));
    });
  });
}
