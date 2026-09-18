import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowledgevault/core/cache/local_cache.dart';

AppDatabase _memoryDb() => AppDatabase(executor: NativeDatabase.memory());

Map<String, dynamic> _row(int id) => {
      'id': id,
      'title': 'Note $id',
      'content': 'body $id',
      'user_id': 1,
      'category_id': null,
      'organization_status': 'organized',
      'created_at': DateTime(2026, 1, id).toIso8601String(),
    };

void main() {
  group('AppDatabase', () {
    late AppDatabase db;
    setUp(() => db = _memoryDb());
    tearDown(() => db.close());

    test('note cache round-trips, newest first', () async {
      await db.cacheNoteRows([_row(1), _row(2)]);
      final rows = await db.getCachedNoteRows();
      expect(rows.map((r) => r['id']), [2, 1]);
    });

    test('offline queue keeps order and is scoped per user', () async {
      final a = await db.enqueueCreateNote(userId: 1, content: 'first');
      await db.enqueueCreateNote(userId: 2, content: 'someone else');
      final b = await db.enqueueCreateNote(userId: 1, content: 'second');

      final ops = await db.getPendingOps(1);
      expect(ops.map((o) => o.payload), ['first', 'second']);
      expect(ops.map((o) => o.id), [a, b]);
      expect(ops.every((o) => o.kind == PendingOp.createNote), isTrue);
      expect(await db.getPendingOps(2), hasLength(1));
    });

    test('deletePendingOp removes only that op', () async {
      final a = await db.enqueueCreateNote(userId: 1, content: 'a');
      await db.enqueueCreateNote(userId: 1, content: 'b');
      await db.deletePendingOp(a);
      expect((await db.getPendingOps(1)).map((o) => o.payload), ['b']);
    });

    test('kv stores and replaces values', () async {
      expect(await db.getKv('k'), isNull);
      await db.setKv('k', 'v1');
      await db.setKv('k', 'v2');
      expect(await db.getKv('k'), 'v2');
    });

    test('clearCachedData wipes cache and profile but keeps unsent notes',
        () async {
      await db.cacheNoteRows([_row(1)]);
      await db.cacheCategoryRows([
        {'id': 1, 'name': 'Ideas'}
      ]);
      await db.setKv('current_user', '{}');
      await db.enqueueCreateNote(userId: 1, content: 'unsent');

      await db.clearCachedData();

      expect(await db.getCachedNoteRows(), isEmpty);
      expect(await db.getCachedCategoryRows(), isEmpty);
      expect(await db.getKv('current_user'), isNull);
      expect(await db.getPendingOps(1), hasLength(1));
    });
  });

  test('data survives closing and reopening the database file', () async {
    final dir = await Directory.systemTemp.createTemp('kv_cache_test');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/kv.sqlite');

    final first = AppDatabase(executor: NativeDatabase(file));
    await first.cacheNoteRows([_row(7)]);
    await first.enqueueCreateNote(userId: 1, content: 'written offline');
    await first.close();

    final second = AppDatabase(executor: NativeDatabase(file));
    addTearDown(second.close);
    expect((await second.getCachedNoteRows()).single['id'], 7);
    expect((await second.getPendingOps(1)).single.payload, 'written offline');
  });
}
