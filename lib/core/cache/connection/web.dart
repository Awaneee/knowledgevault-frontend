import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Needs `web/sqlite3.wasm` and `web/drift_worker.js`, whose versions must
/// match the `sqlite3` and `drift` packages in pubspec.lock.
QueryExecutor openCacheDatabase() => LazyDatabase(() async {
  final result = await WasmDatabase.open(
    databaseName: 'kv_cache',
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.js'),
  );
  return result.resolvedExecutor;
});
