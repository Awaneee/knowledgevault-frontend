import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connection/connection.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// A write the user made while offline, waiting to be sent to the server.
class PendingOp {
  const PendingOp({
    required this.id,
    required this.userId,
    required this.kind,
    required this.payload,
    required this.createdAt,
  });

  final int id;
  final int userId;
  final String kind;
  final String payload;
  final DateTime createdAt;

  static const createNote = 'create_note';
}

/// On-disk SQLite cache: survives app restarts so notes, categories and the
/// signed-in profile can be shown without a network, and holds the queue of
/// writes made offline.
///
/// Pass [executor] to use a different database (tests use in-memory).
class AppDatabase extends GeneratedDatabase {
  AppDatabase({QueryExecutor? executor})
      : super(executor ?? openCacheDatabase());

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await _createSchema();
        },
      );

  Future<void> _createSchema() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS notes (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT,
        user_id INTEGER NOT NULL,
        category_id INTEGER,
        organization_status TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS pending_ops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        kind TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE IF NOT EXISTS kv (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // ── Notes ──────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCachedNoteRows() async {
    final rows = await customSelect(
      'SELECT * FROM notes ORDER BY created_at DESC',
    ).get();
    return rows.map((r) => r.data).toList();
  }

  Future<void> cacheNoteRows(List<Map<String, dynamic>> rows) async {
    await transaction(() async {
      await customStatement('DELETE FROM notes');
      for (final row in rows) {
        await customStatement(
          'INSERT INTO notes VALUES (?,?,?,?,?,?,?)',
          [
            row['id'],
            row['title'],
            row['content'],
            row['user_id'],
            row['category_id'],
            row['organization_status'],
            row['created_at'],
          ],
        );
      }
    });
  }

  // ── Categories ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCachedCategoryRows() async {
    final rows =
        await customSelect('SELECT * FROM categories ORDER BY name').get();
    return rows.map((r) => r.data).toList();
  }

  Future<void> cacheCategoryRows(List<Map<String, dynamic>> rows) async {
    await transaction(() async {
      await customStatement('DELETE FROM categories');
      for (final row in rows) {
        await customStatement(
          'INSERT INTO categories VALUES (?,?)',
          [row['id'], row['name']],
        );
      }
    });
  }

  // ── Key/value (signed-in profile) ──────────────────────────────────────────

  Future<String?> getKv(String key) async {
    final rows = await customSelect(
      'SELECT value FROM kv WHERE key = ?',
      variables: [Variable<String>(key)],
    ).get();
    return rows.isEmpty ? null : rows.first.data['value'] as String;
  }

  Future<void> setKv(String key, String value) async {
    await customStatement(
      'INSERT OR REPLACE INTO kv (key, value) VALUES (?, ?)',
      [key, value],
    );
  }

  // ── Offline write queue ────────────────────────────────────────────────────

  /// Queues a note to be created when the network is back. Returns the queue
  /// id (used to build a stable local placeholder id).
  Future<int> enqueueCreateNote({
    required int userId,
    required String content,
  }) async {
    await customStatement(
      'INSERT INTO pending_ops (user_id, kind, payload, created_at) '
      'VALUES (?, ?, ?, ?)',
      [userId, PendingOp.createNote, content, DateTime.now().toIso8601String()],
    );
    final rows = await customSelect('SELECT last_insert_rowid() AS id').get();
    return rows.first.data['id'] as int;
  }

  /// Pending writes for [userId], oldest first.
  Future<List<PendingOp>> getPendingOps(int userId) async {
    final rows = await customSelect(
      'SELECT * FROM pending_ops WHERE user_id = ? ORDER BY id',
      variables: [Variable<int>(userId)],
    ).get();
    return rows
        .map((r) => PendingOp(
              id: r.data['id'] as int,
              userId: r.data['user_id'] as int,
              kind: r.data['kind'] as String,
              payload: r.data['payload'] as String,
              createdAt: DateTime.parse(r.data['created_at'] as String),
            ))
        .toList();
  }

  Future<void> deletePendingOp(int id) async {
    await customStatement('DELETE FROM pending_ops WHERE id = ?', [id]);
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  /// Drops cached server data and the stored profile. The offline write queue
  /// is kept on purpose: it is per-user and unsent notes must not be lost by
  /// signing out; they sync when that user signs back in.
  Future<void> clearCachedData() async {
    await transaction(() async {
      await customStatement('DELETE FROM notes');
      await customStatement('DELETE FROM categories');
      await customStatement('DELETE FROM kv');
    });
  }
}
