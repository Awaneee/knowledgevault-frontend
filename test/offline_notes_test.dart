import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledgevault/core/api/api_exceptions.dart';
import 'package:knowledgevault/core/cache/local_cache.dart';
import 'package:knowledgevault/core/connectivity/connectivity_banner.dart';
import 'package:knowledgevault/features/auth/data/models/user_response.dart';
import 'package:knowledgevault/features/auth/providers/auth_provider.dart';
import 'package:knowledgevault/features/notes/data/models/note_create_response.dart';
import 'package:knowledgevault/features/notes/data/models/note_response.dart';
import 'package:knowledgevault/features/notes/data/notes_repository.dart';
import 'package:knowledgevault/features/notes/providers/notes_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockNotesRepository extends Mock implements NotesRepository {}

const _user = UserResponse(id: 1, username: 'a', email: 'a@b.c');

NoteResponse _note(int id) => NoteResponse(
      id: id,
      title: 'Note $id',
      userId: 1,
      createdAt: DateTime(2026, 1, id),
    );

NoteCreateResponse _created(int id) => NoteCreateResponse(
      id: id,
      title: 'Created $id',
      userId: 1,
      createdAt: DateTime(2026, 2, 1),
    );

void main() {
  late MockNotesRepository repo;
  late AppDatabase db;
  late StreamController<List<ConnectivityResult>> connectivity;

  setUp(() {
    repo = MockNotesRepository();
    db = AppDatabase(executor: NativeDatabase.memory());
    connectivity = StreamController<List<ConnectivityResult>>.broadcast();
  });

  tearDown(() async {
    await connectivity.close();
    await db.close();
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(overrides: [
      notesRepositoryProvider.overrideWithValue(repo),
      appDatabaseProvider.overrideWithValue(db),
      currentUserProvider.overrideWithValue(_user),
      connectivityProvider.overrideWith((ref) => connectivity.stream),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('offline reads', () {
    test('build serves the cache instead of failing when offline', () async {
      await db.cacheNoteRows([
        {
          'id': 5,
          'title': 'Cached',
          'content': null,
          'user_id': 1,
          'category_id': null,
          'organization_status': null,
          'created_at': DateTime(2026, 1, 5).toIso8601String(),
        }
      ]);
      when(() => repo.listNotes()).thenThrow(const NetworkException());

      final notes = await makeContainer().read(notesProvider.future);

      expect(notes.map((n) => n.id), [5]);
    });

    test('build still errors when offline with nothing cached', () async {
      when(() => repo.listNotes()).thenThrow(const NetworkException());
      await expectLater(
        makeContainer().read(notesProvider.future),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('offline writes', () {
    test('createNote offline queues the note and shows a placeholder',
        () async {
      when(() => repo.listNotes()).thenAnswer((_) async => [_note(1)]);
      when(() => repo.createNote(any())).thenThrow(const NetworkException());
      final c = makeContainer();
      await c.read(notesProvider.future);

      final result =
          await c.read(notesProvider.notifier).createNote('Buy milk\nand eggs');

      expect(result, isNull);
      final first = c.read(notesProvider).valueOrNull!.first;
      expect(isPendingNoteId(first.id), isTrue);
      expect(first.title, 'Buy milk');
      expect(first.organizationStatus, pendingSyncStatus);
      expect((await db.getPendingOps(1)).single.payload, 'Buy milk\nand eggs');
    });

    test('queued note survives a restart (new container, same database)',
        () async {
      when(() => repo.listNotes()).thenThrow(const NetworkException());
      when(() => repo.createNote(any())).thenThrow(const NetworkException());
      await db.cacheNoteRows([
        {
          'id': 1,
          'title': 'Cached',
          'content': null,
          'user_id': 1,
          'category_id': null,
          'organization_status': null,
          'created_at': DateTime(2026, 1, 1).toIso8601String(),
        }
      ]);
      final first = makeContainer();
      await first.read(notesProvider.future);
      await first.read(notesProvider.notifier).createNote('written offline');

      final restarted = await makeContainer().read(notesProvider.future);

      expect(restarted.first.content, 'written offline');
      expect(isPendingNoteId(restarted.first.id), isTrue);
      expect(restarted.any((n) => n.id == 1), isTrue);
    });

    test('reconnecting sends queued notes in order and clears the queue',
        () async {
      when(() => repo.listNotes()).thenThrow(const NetworkException());
      final c = makeContainer();
      await db.cacheNoteRows([]);
      await db.enqueueCreateNote(userId: 1, content: 'first');
      await db.enqueueCreateNote(userId: 1, content: 'second');
      // Start offline (cache empty but queue non-empty → placeholders shown).
      await c.read(notesProvider.future);

      var next = 100;
      when(() => repo.createNote(any()))
          .thenAnswer((_) async => _created(next++));
      when(() => repo.listNotes())
          .thenAnswer((_) async => [_note(100), _note(101)]);

      connectivity.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      verifyInOrder([
        () => repo.createNote('first'),
        () => repo.createNote('second'),
      ]);
      expect(await db.getPendingOps(1), isEmpty);
      final notes = c.read(notesProvider).valueOrNull!;
      expect(notes.any((n) => isPendingNoteId(n.id)), isFalse);
      expect(notes.map((n) => n.id), containsAll([100, 101]));
    });

    test('still offline during sync keeps the queue intact', () async {
      when(() => repo.listNotes()).thenThrow(const NetworkException());
      when(() => repo.createNote(any())).thenThrow(const NetworkException());
      final c = makeContainer();
      await db.enqueueCreateNote(userId: 1, content: 'keep me');
      await c.read(notesProvider.future);

      final synced = await c.read(notesProvider.notifier).syncPending();

      expect(synced, 0);
      expect(await db.getPendingOps(1), hasLength(1));
    });

    test('a note the server rejects is dropped so it cannot block the queue',
        () async {
      when(() => repo.listNotes()).thenThrow(const NetworkException());
      final c = makeContainer();
      await db.enqueueCreateNote(userId: 1, content: 'bad');
      await db.enqueueCreateNote(userId: 1, content: 'good');
      await c.read(notesProvider.future);

      when(() => repo.createNote('bad'))
          .thenThrow(const ValidationException('too long'));
      when(() => repo.createNote('good'))
          .thenAnswer((_) async => _created(200));
      when(() => repo.listNotes()).thenAnswer((_) async => [_note(200)]);

      final synced = await c.read(notesProvider.notifier).syncPending();

      expect(synced, 1);
      expect(await db.getPendingOps(1), isEmpty);
    });

    test('server error keeps the note queued for a later retry', () async {
      when(() => repo.listNotes()).thenThrow(const NetworkException());
      final c = makeContainer();
      await db.enqueueCreateNote(userId: 1, content: 'retry me');
      await c.read(notesProvider.future);
      when(() => repo.createNote(any()))
          .thenThrow(const ServerException('boom'));

      await c.read(notesProvider.notifier).syncPending();

      expect(await db.getPendingOps(1), hasLength(1));
    });

    test('deleting a pending note just removes it from the queue', () async {
      when(() => repo.listNotes()).thenThrow(const NetworkException());
      final c = makeContainer();
      final opId = await db.enqueueCreateNote(userId: 1, content: 'oops');
      await c.read(notesProvider.future);

      await c.read(notesProvider.notifier).deleteNote(-opId);

      expect(await db.getPendingOps(1), isEmpty);
      verifyNever(() => repo.deleteNote(any()));
      expect(c.read(notesProvider).valueOrNull, isEmpty);
    });
  });
}
