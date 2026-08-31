import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// In-memory SQLite database for Phase 3 session caching.
/// Phase 5 will switch to a file-based [NativeDatabase] for cross-restart persistence.
class AppDatabase extends GeneratedDatabase {
  AppDatabase() : super(NativeDatabase.memory());

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
}
